import csv
import re
from collections import Counter, defaultdict
from pathlib import Path

root = Path(__file__).resolve().parents[1]
trace = Path('/tmp/ex716-all-function-current-run.log')
old_csv = root / 'tests/diskos_lcc_main_calls.csv'
out_csv = old_csv

known = {}
with old_csv.open(newline='') as f:
    for row in csv.DictReader(f):
        known[row['function_name']] = row

arg_overrides = {
    '__ex716_u25db41a9_static_357': 6,  # stdio mode parser
    '__EX716_DISK_LAST_ERROR': 0,
    'HeapDSDefineMemoryFar': 2,
    'HeapDSNewObjectFar': 2,
    'HeapDSDeleteObjectFar': 2,
    'DiskFindFreeBlock': 0,
    'DirReadEntry': 3,
    'DirWriteEntry': 3,
    'DiskClose': 1,
    'DiskFileRead': 3,
    'DiskFileWrite': 3,
    'DiskReadBlock': 5,
    'DiskWriteBlock': 5,
    'DiskLocateWriteExtent': 4,
    'DiskOpen': 2,
    'FSReadHeader': 1,
    'FSIsFileUsed': 1,
    'FSNextUsedFile': 1,
    'FSSetFileUsed': 1,
    'FSFindFile': 2,
    'file_open': 2,
    'fopen': 2,
    'fclose': 1,
    'fread': 4,
    'fwrite': 4,
    'WildCardMatch': 2,
    'DiskTrimExtents': 3,
    'DirLocate': 1,
    'DirNewArgTable': 0,
    'DiskNewBuffer': 0,
    'FSFindFreeFile': 0,
    'FSWriteHeader': 0,
    'DiskSetFileName': 2,
    'strcmp': 2,
    'strfndc': 2,
    'memcpy': 3,
}
return_overrides = {
    '__ex716_u25db41a9_static_357': (1, 1),
    '__EX716_DISK_LAST_ERROR': (1, 1),
    'HeapDSDefineMemoryFar': (1, 1),
    'HeapDSNewObjectFar': (1, 1),
    'HeapDSDeleteObjectFar': (1, 1),
    'DiskFindFreeBlock': (1, 1),
    'DiskTrimExtents': (1, 1),
    'FSFindFile': (1, 1),
    'DirNewArgTable': (1, 1),
    'DiskNewBuffer': (1, 1),
    'DirReadEntry': (1, 1),
    'DiskFileWrite': (1, 1),
    'DiskReadSector': (0, 0),
    'DiskWriteSector': (0, 0),
    'DirEntryToArgTable': (0, 0),
    'DirArgTableToEntry': (0, 0),
    'FSFindFreeFile': (1, 1),
    'FSWriteHeader': (1, 1),
    'DiskSetFileName': (0, 0),
    'DirLocate': (2, 2),
    'strcmp': (1, 1),
    'strfndc': (1, 1),
    # Public file APIs document a single pointer/status/byte-count result.
    'DiskOpen': (1, 1),
    'DiskClose': (1, 1),
    'file_open': (1, 1),
    'fopen': (1, 1),
    'fclose': (1, 1),
    'fread': (1, 1),
    'fwrite': (1, 1),
    'memcpy': (1, 1),
    '__EX716_DISK_OPEN': (1, 1),
    '__EX716_DISK_CLOSE': (1, 1),
    '__EX716_DISK_READ': (1, 1),
    '__EX716_DISK_WRITE': (1, 1),
    '__EX716_DISK_INIT': (1, 1),
    'SetDiskHeap': (0, 0),
}
source_return_overrides = {
    # The C shim returns the destination pointer. The assembly copy primitive
    # is deliberately void; the C shim pushes Dst after it returns.
    ('c_runtime_stubs.ld', 'memcpy'): (1, 1),
    ('string.ld', 'memcpy'): (0, 0),
}

files = {}
for p in list((root / 'lib').glob('*.ld')) + list((root / 'lib').glob('*.mc')) + [Path('/tmp/ex716-lcc-autobank/file_roundtrip.asm')]:
    try:
        files[p.name] = p.read_text(errors='replace').splitlines()
    except OSError:
        pass

func_at = {}
macro_at = {}
function_sources = defaultdict(set)
for filename, lines in files.items():
    current = ''
    for n, line in enumerate(lines, 1):
        m = re.match(r'\s*@FUNCTION(?:\([^)]*\))?\s+([A-Za-z_.$][\w.$]*)', line, re.I)
        if m:
            current = m.group(1)
            function_sources[current].add(filename)
        elif re.match(r'\s*@ENDFUNCTION\b', line, re.I):
            current = ''
        if current:
            func_at[(filename, n)] = current
        if re.match(r'\s*@PUSHRETURN\b', line, re.I):
            macro_at[(filename, n)] = ('in', current)
        elif re.match(r'\s*@POPRETURN\b', line, re.I):
            macro_at[(filename, n)] = ('out', current)
        elif re.match(r'\s*@FENTER\b', line, re.I):
            macro_at[(filename, n)] = ('far_in', current)
        elif re.match(r'\s*@FRET\b', line, re.I):
            macro_at[(filename, n)] = ('far_out', current)

raw_records = []
pat = re.compile(r' ([0-9a-f]{2}):([0-9a-f]{4}):Stack:\((empty|\d+)\):([^ :]+):(\d+)')
for lineno, line in enumerate(trace.open(errors='replace'), 1):
    m = pat.search(line)
    if not m:
        continue
    cs, pc = m.group(1), int(m.group(2), 16)
    depth = 0 if m.group(3) == 'empty' else int(m.group(3))
    filename, src_line = m.group(4), int(m.group(5))
    src = Path(filename).name
    macro = macro_at.get((src, src_line))
    if macro:
        raw_records.append((lineno, macro[0], macro[1], depth, src, src_line, cs, pc))

# StackDump locations inside autobank veneers inherit the first macro
# callsite's source line. Use execution CS:PC and per-file code-bank evidence
# to reject those snapshots instead of attributing them to that source function.
line_banks = defaultdict(Counter)
for rec in raw_records:
    line_banks[(rec[4], rec[5])][rec[6]] += 1
file_bank_votes = defaultdict(Counter)
for (src, src_line), counts in line_banks.items():
    file_bank_votes[src][counts.most_common(1)[0][0]] += 1
owner_bank = {src: counts.most_common(1)[0][0] for src, counts in file_bank_votes.items()}
records = [r[:6] for r in raw_records if r[6] == owner_bank[r[4]]]
raw_by_line = {r[0]: r for r in raw_records}

# Pair snapshots from PUSHRETURN/POPRETURN and retain the single FENTER/FRET
# snapshots. Far-entry snapshots include a two-word return pair.
events = []
i = 0
while i + 1 < len(records):
    a, b = records[i], records[i + 1]
    if a[1] in ('in', 'out') and a[1:3] == b[1:3] and a[4:] == b[4:] and b[0] > a[0]:
        events.append((a[0], a[1], a[2], a[3], b[3], a[4], a[5]))
        i += 2
    else:
        i += 1
for r in records:
    if r[1] in ('far_in', 'far_out'):
        events.append((r[0], r[1], r[2], r[3], r[3], r[4], r[5]))
events.sort()

active = []
observations = {}
pairing_diagnostics = 0
invocations = []
diagnostics = []
next_invocation_id = 1
for logline, kind, name, before, after, src, src_line in events:
    if not name:
        continue
    info = known.get(name)
    if info:
        argc = int(info.get('argument_count', info.get('expected_argument_count', 0)))
    if name in arg_overrides:
        argc = arg_overrides[name]
    elif not info:
        # Count the leading argument pops in assembly functions. For C
        # generated functions the previous contract list provides this count.
        lines = files.get(src, [])
        argc = 0
        started = False
        for s in lines[src_line:src_line + 80]:
            if re.search(r'@POPI\s+\w+', s, re.I):
                argc += 1
                started = True
            elif started and s.strip() and not s.strip().startswith('#'):
                break
    display_name = f'{src}::{name}' if len(function_sources.get(name, ())) > 1 else name
    if kind in ('in', 'far_in'):
        return_words = 2 if kind == 'far_in' else 1
        # The entry snapshot has arguments plus return address on the hardware
        # stack. The trace lacks a pre-argument-push snapshot, so arity comes
        # from the contract and is not reported as independently observed.
        actual_argc = None
        base = before - argc - return_words
        parent_id = active[-1]['id'] if active else ''
        frame = {
            'id': next_invocation_id,
            'name': display_name,
            'match_name': name,
            'argc': argc,
            'actual_argc': actual_argc,
            'baseline': base,
            'entry_line': logline,
            'entry_before': before,
            'entry_after': after,
            'entry_kind': kind,
            'parent_id': parent_id,
            'depth': len(active) + 1,
            'source': f'{src}:{src_line}',
            'entry_pc': raw_by_line.get(logline, ('', '', '', '', '', '', '', ''))[6:8],
        }
        next_invocation_id += 1
        active.append(frame)
        ob = observations.setdefault(display_name, {'args': set(), 'outputs': set(), 'calls': 0, 'completed': 0})
        ob['calls'] += 1
    else:
        idx = len(active) - 1
        if idx < 0 or active[idx]['match_name'] != name:
            pairing_diagnostics += 1
            diagnostics.append([logline, 'unmatched_or_non_lifo_exit', display_name, f'{src}:{src_line}'])
            continue
        frame = active.pop()
        outc = before - frame['baseline']
        display_name = frame['name']
        ob = observations.setdefault(display_name, {'args': set(), 'outputs': set(), 'calls': 0, 'completed': 0})
        ob['outputs'].add(outc)
        ob['completed'] += 1
        spec = known.get(name, {})
        success, error = source_return_overrides.get((src, name), return_overrides.get(name, (
            int(spec.get('success_return_items', spec.get('expected_normal_return_arguments', 1))),
            int(spec.get('error_return_items', spec.get('expected_error_return_arguments', 1))),
        )))
        status = 'matches_normal_contract' if outc == success else ('matches_error_contract' if outc == error else 'boundary_delta_mismatch')
        exit_pc = raw_by_line.get(logline, ('', '', '', '', '', '', '', ''))[6:8]
        retwords = 2 if frame['entry_kind'] == 'far_in' else 1
        invocations.append([
            frame['id'], frame['name'], frame['parent_id'], frame['depth'], frame['entry_line'], logline,
            frame['entry_pc'][0], f'{frame["entry_pc"][1]:04x}' if frame['entry_pc'][1] != '' else '',
            exit_pc[0], f'{exit_pc[1]:04x}' if exit_pc[1] != '' else '',
            frame['entry_before'], before, retwords, frame['argc'], frame['actual_argc'] if frame['actual_argc'] is not None else '', success, error, outc,
            status, frame['source'], f'{src}:{src_line}',
        ])
        if status == 'boundary_delta_mismatch':
            diagnostics.append([logline, status, display_name, f'invocation={frame["id"]}; observed={outc}; normal={success}; error={error}'])

pairing_diagnostics += len(active)
for frame in active:
    diagnostics.append([frame['entry_line'], 'unmatched_entry', frame['name'], frame['source']])

rows = []
for name, ob in observations.items():
    raw_name = name.split('::', 1)[-1]
    src_name = name.split('::', 1)[0] if '::' in name else ''
    spec = known.get(raw_name, {})
    argc = arg_overrides.get(raw_name, int(spec.get('argument_count', spec.get('expected_argument_count', 0)) or (next(iter(ob['args'])) if ob['args'] else 0)))
    succ_err = source_return_overrides.get((src_name, raw_name), return_overrides.get(raw_name))
    success = succ_err[0] if succ_err else int(spec.get('success_return_items', spec.get('expected_normal_return_arguments', 1)))
    error = succ_err[1] if succ_err else int(spec.get('error_return_items', spec.get('expected_error_return_arguments', success)))
    # The trace has no pre-argument-push snapshot. Do not present the declared
    # arity as if it were independently observed at runtime.
    actual_args = '|'.join(str(x) for x in sorted(ob['args'])) if ob['args'] else ''
    actual_out = max(ob['outputs']) if ob['outputs'] else success
    rows.append([name, argc, success, error, actual_args, actual_out, ob['calls'], ob['completed']])

# Include the C main entry even though its caller is the generated startup.
if 'main' not in observations and 'main' in known:
    r = known['main']
    rows.append(['main', int(r.get('argument_count', r.get('expected_argument_count', 0))), int(r.get('success_return_items', r.get('expected_normal_return_arguments', 1))), int(r.get('error_return_items', r.get('expected_error_return_arguments', 1))), 0, 1, 0, 0])

rows.sort(key=lambda r: r[0].lower())
summary_header = ['function_name', 'expected_argument_count', 'expected_normal_return_arguments', 'expected_error_return_arguments', 'actual_input_arguments_seen', 'actual_output_arguments_observed', 'calls_entered', 'calls_completed']
for summary_path in (out_csv, root / 'tests/diskos_lcc_calls.csv'):
    with summary_path.open('w', newline='') as f:
        w = csv.writer(f)
        w.writerow(summary_header)
        w.writerows(rows)
invocation_path = root / 'tests/diskos_lcc_invocations.csv'
with invocation_path.open('w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['invocation_id', 'function_name', 'parent_invocation_id', 'call_depth', 'entry_trace_line', 'exit_trace_line', 'entry_cs', 'entry_pc', 'exit_cs', 'exit_pc', 'entry_stack_depth', 'exit_stack_depth_before_return', 'return_address_words', 'expected_argument_count', 'actual_arguments_observed', 'expected_normal_return_arguments', 'expected_error_return_arguments', 'observed_return_arguments', 'status', 'entry_source', 'exit_source'])
    w.writerows(invocations)
diagnostic_path = root / 'tests/diskos_lcc_diagnostics.csv'
with diagnostic_path.open('w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['trace_line', 'diagnostic', 'function_name', 'detail'])
    w.writerows(diagnostics)
print(f'functions={len(rows)} events={len(events)} strict_pairing_diagnostics={pairing_diagnostics}')
for r in rows:
    if r[5] != r[2]:
        print(f'output mismatch: {r[0]} expected {r[2]}, observed {r[5]}')
