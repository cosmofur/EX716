#ifndef VM_EVENTS_H
#define VM_EVENTS_H

#include <stdint.h>

/* Device events and interrupt requests are deliberately separate from the
 * executor's signed RC_* return codes.  Bits describe coalescible work; a
 * device that needs every occurrence must keep its own counter or queue. */
#define VM_EVENT_NONE 0u
#define VM_EVENT_TIMER (1u << 0)
#define VM_EVENT_DEVICE (1u << 1)
#define VM_EVENT_NO_DEADLINE UINT64_MAX
#define VM_EVENT_SCHEDULE_SLOTS 8u

typedef enum {
    VM_EVENT_SERVICE_OK = 0,
    VM_EVENT_SERVICE_FAILED = 1
} VMEventServiceResult;

struct VMEventState;
typedef VMEventServiceResult (*VMEventServiceFn)(struct VMEventState *, void *);

typedef struct {
    uint64_t deadline;
    uint32_t events;
} VMEventDeadline;

typedef struct VMEventState {
    uint32_t pending_events;
    uint32_t pending_interrupts;
    uint64_t instruction_count;
    uint64_t next_deadline;
    VMEventDeadline scheduled[VM_EVENT_SCHEDULE_SLOTS];
    VMEventServiceFn service;
    void *service_context;
} VMEventState;

void vm_events_init(VMEventState *state);
void vm_events_set_service(VMEventState *state, VMEventServiceFn service,
                           void *service_context);
void vm_events_schedule_after(VMEventState *state, uint64_t instructions,
                              uint32_t event_flags);
void vm_events_raise(VMEventState *state, uint32_t event_flags);
void vm_events_request_interrupt(VMEventState *state, uint32_t interrupt_flags);
int vm_events_after_instruction(VMEventState *state);
VMEventServiceResult vm_events_service(VMEventState *state);
int vm_events_resolve_return_code(int execution_return_code,
                                  VMEventServiceResult service_result,
                                  int service_failure_code);

#endif
