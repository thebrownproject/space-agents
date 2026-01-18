#!/bin/bash
# POC: Ralph-like script that spawns "pods" via mprocs --ctl

echo "Ralph starting..."
sleep 2

# Simulate spawning pods for objectives
for i in 1 2 3; do
    echo "Ralph: Spawning Pod for OBJ-00$i"
    mprocs --ctl "{c: add-proc, cmd: \"echo 'Pod OBJ-00$i starting...' && sleep 5 && echo 'Pod OBJ-00$i complete'\", name: \"Pod-OBJ-00$i\"}"
    echo "Ralph: Waiting for Pod..."
    sleep 7  # Wait for pod to finish (in real version, we'd check exit)
    echo "Ralph: OBJ-00$i done, next objective..."
done

echo "Ralph: All objectives complete!"
echo "Press Enter to exit..."
read
