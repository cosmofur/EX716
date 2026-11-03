#include <assert.h>
#include <string.h>

#include "vm_console.h"
#include "vm_events.h"

static VMEventServiceResult consume_events(VMEventState *state, void *context)
{
    unsigned int *calls = context;
    ++*calls;
    state->pending_events = VM_EVENT_NONE;
    return VM_EVENT_SERVICE_OK;
}

static VMEventServiceResult fail_service(VMEventState *state, void *context)
{
    (void)state;
    (void)context;
    return VM_EVENT_SERVICE_FAILED;
}

int main(void)
{
    VMEventState events;
    VMConsole console;
    unsigned int calls = 0;
    unsigned char drained[VM_CONSOLE_GUEST_BUFFER_SIZE];
    unsigned char excess[VM_CONSOLE_GUEST_BUFFER_SIZE + 3];

    vm_events_init(&events);
    assert(!vm_events_after_instruction(&events));
    vm_events_schedule_after(&events, 2, VM_EVENT_TIMER);
    vm_events_schedule_after(&events, 3, VM_EVENT_DEVICE);
    assert(!vm_events_after_instruction(&events));
    assert(vm_events_after_instruction(&events));
    assert(events.pending_events == VM_EVENT_TIMER);
    events.pending_events = VM_EVENT_NONE;
    assert(vm_events_after_instruction(&events));
    assert(events.pending_events == VM_EVENT_DEVICE);
    events.pending_events = VM_EVENT_TIMER;
    vm_events_raise(&events, VM_EVENT_DEVICE);
    vm_events_request_interrupt(&events, 0x20u);
    assert(events.pending_events == (VM_EVENT_TIMER | VM_EVENT_DEVICE));
    assert(events.pending_interrupts == 0x20u);
    vm_events_set_service(&events, consume_events, &calls);
    assert(vm_events_service(&events) == VM_EVENT_SERVICE_OK);
    assert(calls == 1 && events.pending_events == VM_EVENT_NONE);
    vm_events_set_service(&events, fail_service, 0);
    assert(vm_events_service(&events) == VM_EVENT_SERVICE_FAILED);
    assert(vm_events_resolve_return_code(-1, VM_EVENT_SERVICE_FAILED, -12) == -1);
    assert(vm_events_resolve_return_code(-4, VM_EVENT_SERVICE_FAILED, -12) == -4);
    assert(vm_events_resolve_return_code(0, VM_EVENT_SERVICE_FAILED, -12) == -12);

    vm_console_init(&console);
    vm_console_set_guest_mode(&console, VM_CONSOLE_GUEST_BUFFERED);
    vm_console_write(&console, VM_CONSOLE_GUEST_TEXT, "abc", 3);
    assert(vm_console_guest_length(&console) == 3);
    assert(vm_console_drain_guest(&console, drained, sizeof(drained)) == 3);
    assert(memcmp(drained, "abc", 3) == 0);
    memset(excess, 'x', sizeof(excess));
    vm_console_write(&console, VM_CONSOLE_GUEST_TEXT, excess, sizeof(excess));
    assert(vm_console_guest_length(&console) == VM_CONSOLE_GUEST_BUFFER_SIZE);
    assert(vm_console_guest_overflow(&console) == 3);
    assert(vm_console_drain_guest(&console, drained, sizeof(drained)) ==
           VM_CONSOLE_GUEST_BUFFER_SIZE);
    return 0;
}
