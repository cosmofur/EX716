#include "vm_events.h"

static void vm_events_refresh_deadline(VMEventState *state)
{
    unsigned int index;
    state->next_deadline = VM_EVENT_NO_DEADLINE;
    for (index = 0; index < VM_EVENT_SCHEDULE_SLOTS; ++index) {
        if (state->scheduled[index].events != VM_EVENT_NONE &&
            state->scheduled[index].deadline < state->next_deadline) {
            state->next_deadline = state->scheduled[index].deadline;
        }
    }
}

void vm_events_init(VMEventState *state)
{
    state->pending_events = VM_EVENT_NONE;
    state->pending_interrupts = VM_EVENT_NONE;
    state->instruction_count = 0;
    state->next_deadline = VM_EVENT_NO_DEADLINE;
    state->service = 0;
    state->service_context = 0;
    for (unsigned int index = 0; index < VM_EVENT_SCHEDULE_SLOTS; ++index) {
        state->scheduled[index].deadline = VM_EVENT_NO_DEADLINE;
        state->scheduled[index].events = VM_EVENT_NONE;
    }
}

void vm_events_set_service(VMEventState *state, VMEventServiceFn service,
                           void *service_context)
{
    state->service = service;
    state->service_context = service_context;
}

void vm_events_schedule_after(VMEventState *state, uint64_t instructions,
                              uint32_t event_flags)
{
    uint64_t deadline = state->instruction_count + instructions;
    unsigned int index;
    unsigned int free_slot = VM_EVENT_SCHEDULE_SLOTS;

    /* An immediate event is visible to the next instruction-boundary service
     * point without waiting for the retired-instruction clock to advance. */
    if (instructions == 0) {
        vm_events_raise(state, event_flags);
        return;
    }

    for (index = 0; index < VM_EVENT_SCHEDULE_SLOTS; ++index) {
        if (state->scheduled[index].events == VM_EVENT_NONE) {
            if (free_slot == VM_EVENT_SCHEDULE_SLOTS) free_slot = index;
        } else if (state->scheduled[index].deadline == deadline) {
            state->scheduled[index].events |= event_flags;
            vm_events_refresh_deadline(state);
            return;
        }
    }
    /* The initial fixed queue has no allocation path.  Do not lose a device
     * event if it fills: make it pending now.  A device needing exact delayed
     * occurrence accounting should use its own queue/counter. */
    if (free_slot == VM_EVENT_SCHEDULE_SLOTS) {
        vm_events_raise(state, event_flags);
        return;
    }
    state->scheduled[free_slot].deadline = deadline;
    state->scheduled[free_slot].events = event_flags;
    vm_events_refresh_deadline(state);
}

void vm_events_raise(VMEventState *state, uint32_t event_flags)
{
    state->pending_events |= event_flags;
}

void vm_events_request_interrupt(VMEventState *state, uint32_t interrupt_flags)
{
    state->pending_interrupts |= interrupt_flags;
}

int vm_events_after_instruction(VMEventState *state)
{
    unsigned int index;
    /* This is the retired-instruction clock.  The caller invokes us only for
     * an instruction that completed architecturally, including a normal stop
     * such as CAST End or debug-toggle. */
    ++state->instruction_count;
    if (state->next_deadline == VM_EVENT_NO_DEADLINE) {
        return state->pending_events != VM_EVENT_NONE;
    }
    if (state->instruction_count < state->next_deadline) {
        return state->pending_events != VM_EVENT_NONE;
    }
    for (index = 0; index < VM_EVENT_SCHEDULE_SLOTS; ++index) {
        if (state->scheduled[index].events != VM_EVENT_NONE &&
            state->scheduled[index].deadline <= state->instruction_count) {
            state->pending_events |= state->scheduled[index].events;
            state->scheduled[index].events = VM_EVENT_NONE;
            state->scheduled[index].deadline = VM_EVENT_NO_DEADLINE;
        }
    }
    vm_events_refresh_deadline(state);
    return state->pending_events != VM_EVENT_NONE;
}

VMEventServiceResult vm_events_service(VMEventState *state)
{
    if (state->service == 0) {
        return VM_EVENT_SERVICE_OK;
    }
    return state->service(state, state->service_context);
}

int vm_events_resolve_return_code(int execution_return_code,
                                  VMEventServiceResult service_result,
                                  int service_failure_code)
{
    if (execution_return_code != 0) return execution_return_code;
    return service_result == VM_EVENT_SERVICE_OK ? 0 : service_failure_code;
}
