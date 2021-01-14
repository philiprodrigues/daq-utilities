#!/usr/bin/env python

from graphviz import Digraph
import json
import sys
import jq
from pprint import pprint

f=open(sys.argv[1])
j=json.load(f)

dot=Digraph()
#dot.attr(splines="compound")
dot.attr(rankdir='LR')

# Map from queue name to list of modules which have that queue as inputs
inputs={}
# Map from queue name to list of modules which have that queue as outputs
outputs={}

# Everything we need is in the "init" command's modules section. If we
# wanted to display anything about the _type_ of the queues, we'd need
# to look at the init command's queues section too
modules=jq.compile('.[] | select(.id == "init").data.modules').input(j)

for m in modules.all()[0]:
    modname=m["inst"]
    # TODO: Would be nicer to have either the plugin name or the
    # instance name larger so it stands out
    dot.node(m["inst"], "{}\n{}".format(m["plugin"], modname),
             shape="box")
    qinfos=m["data"]["qinfos"]
    for q in qinfos:
        print("{} {} ".format(q["inst"], q["dir"]))
        dirn=q["dir"]
        if dirn=="input":
            inputs.setdefault(q["inst"], []).append(modname)
        elif dirn=="output":
            outputs.setdefault(q["inst"], []).append(modname)
        else:
            print("Unknown dir type {}".format(dirn))

for k,vin in inputs.items():
    vout=outputs[k]
    for mod1 in vin:
        for mod2 in vout:
            dot.edge(mod2, mod1, label=k)

dot.render("foo")
