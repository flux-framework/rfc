## Glossary:

This is a partial list that assumes knowledge of the flux terms defined in
RFC#8, some terms from that document are extended below to include their
definition in a job specification (jobspec) context.


- **Group:** A logical resource type used for adding information to the
  resource graph where a resource is unavailable.
- **Id-List:** A possibly-condensed name/id set, following the semantics of a
  hostlist
- **Resource:** A single resource vertex, consisting of either: a resource
  type/name and range; or an id-list.  Each resource may optionally contain
  attributes and *edges* connecting to other resources.
- **Edges:** Conceptually every specification is a directed graph of nodes and
  edges.  Edges consist of a source, destination, type and attributes.  Edges
  from root to child `(cluster->Rack->Node...)` of type "with" form the
  hardware tree, and can be assumed to be directed to form a strict tree.
- **Slot (Task Slot):** A resource with an associated task. The leaf-resources in a
  resource-tree under a program are implicitly converted into slots if no
  slots are explicitly specified in the tree.
- **Sharing:** A resource may be allocated as: exclusive, unique to this job;
  shared, may be oversubscribed by any other job; or self-shared, may only be
  oversubscribed by other tasks from this job.  By default, leaf resources are
  allocated exclusive and others shared.  These may each be overridden.
- **Command:** A command-line to run a single process of the target application.
- **Range:** Valid range of counts for a given associated construct.  Consists
of a minimum, maximum, stride operator and stride value in the form
`\[<min>[:<max>[:[<stride-op>]<stride-val>]]\]`.  A range can be specified in
long-form context without the brackets.  The default value of a range is
min=1, stride-op=+ and stride-val=1.
- **Range-Type:** How to interpret a range, either as a total or as a function
  of the count of some other construct.  Currently only valid on tasks with
  values "per-shard" or "total"
- **Task:** A process, and its children, launched directly by flux.
Consists of a *command*, *tags*, *range*, and *range type*.
- **Program:** A single unit of scheduling, all tasks under a program will be
run together.  Consists of a list of dependencies, tags, and a tree of one
or more resources where at least one resource in the tree must be associated
with a *task*, thus making it a *slot* or *shard*.
- **Job:** The highest level of organization in a jobspec, a list of one or
more *programs*.


## Canonical jobspec

A short-form of the spec is likely to be required to be practical on the
command line, but the canonical representation should form the basis for other
versions.  This is a leaner version of what we've previously discussed, but
retains the core features while simplifying the parsing and requirements in
the short term.  Examples are presented in YAML, but any nested key-value
format would be reasonable, and in fact lua may be wise as the final form once
constraints can be determined.  Either way, the general format should stay the
same.

### General structure

A jobspec is composed of at least one task specification and one resource
specification. This document discusses these things as specified together, but
it is likely that components of each will be generated from command-line
arguments in some cases.  Assume strings are matched case-insensitive by
default.  The general form follows:

```yaml
program:
    <program properties> #wallclock, etc, are set at this level
    tasks: #optional top-level task specification, will be inherited by inner
           #tasks
        name: #optional name to disambiguate this task of this program
        command: #string or list of arguments
        count: #number of tasks of this type to run
        slot: #name of slot to associate with, only meaningful on top-level
              #task-spec
        attributes: #arbitrary dictionary of attributes
    resources: # list of required resources, nested to allow with-a
               # relationships
        type: #resource type
        name: #resource name or expression
        id: #resource id or expression
        count: #number of discrete instances of this resource required
        amount: <num><unit>#amount of given resource required, for pool
                           #resources, exclusive of count
        with: #special shorthand for edges: { type: with, ...}
        edges:
            - type: #edge type
              attributes: # arbitrary attributes
              count: #number of edges of this type allowed
```

The outermost "program" name can be assumed in most user-specified contexts,
and is in examples below.

### Run a flux instance on one Node

Long:

```yaml
resources:
    type: node
```

### Run an instance on between 9 and 300 nodes, allowing only counts which are cubes of 9

Long:

```yaml
resources:
    type: node
    count: 
        min: 9
        max: 300
        stride:^3

--- # OR

resources:
    type: node[9:300:^3]
```

### Run `hostname` 20 times, 5 each on four nodes

Long:

```yaml
resources:
  - type: node
    count: 4
    tasks:
        command: hostname
        count: 5 # replicate 5 times *per node*
```

Possible CLI version: `-r 'node[4]' -t 5 hostname`

### 11 tasks, one node, first 10 using one core and 4G of RAM for `read-db`, last using 6 cores and 24G of RAM for `db`

Generally, the author would recommend using the long-form or a submission
script for this, but in case one wants to do it...

Long:

```yaml
resources:
    - type: node
      with:
        - type: group # Note, special resource type "group" to add a level
          tasks: 
              command: read-db
              count: 10
          with: 
            - core
            - type: Memory
              amount: 4GB
        - type: group
          tasks: 
              command: db
          with:
            - type: Core
              count: 6
            - type: Memory
              amount: 24GB
```

### Crazy example from OAR

"ask for 1 core on 2 nodes on the same cluster with 4096 GB of memory and Infiniband 10G + 1 cpu on 2 nodes on the same switch with bicore processors for a walltime of 4 hours"

```yaml
resources:
    - type: Cluster
      with:
        - type: Node
          count: 2
          with:
            - type: Memory
              amount: 4096GB
            - type: InfiniBand10G
        - type: Switch
          with:
            type: Node
            count: 2
            with:
                type: Core
walltime: 4h
```

Or short: `Cluster(>Node[2](>Memory[4096]GB,>InfiniBand10G),>Switch>Node[2]>Core)`

## Concept

Every jobspec is logically a list of programs, which are each composed of a
tree of resources/slots. This section will touch on what each of these
requires and may contain, each is prefixed with the long-form key or attribute
name used to represent the property.

### Program

A program MUST contain:
- *resources*: a list of one or more resources
- One or more slots, resources with task specifications, in the tree rooted at
  *resources*

A program MAY contain:
- *attributes* a list of zero or more tags
- *dependencies* a list of zero or more dependencies, when no dependencies
  exist, a per-job logical dependency can be assumed

### Resource

A resource node MUST contain:
- One of:
    - *type* and *count*, where the count may default to 1 OR
    - *id-list* of the hostlist form representing the unique IDs of the
      constituent resources OR
    - *uuid-list* a list of uuids, referencing all constituent resources

A resource MAY contain:
- *edges* a list of edges to other resources or nodes generally, in or out, of
  any type, a link of type `t` may also be represented by a key named `t>` for
  an outbound link `<t` for an inbound link or `<t>` for an omnidirectional
  link.  When specified as such, the link accepts a list of targets, this is
  most often seen in the form of `with>`, the standard way to reference child
  resources from a parent resource.
- *tags* a dictionary of key-value pairs, assume this to be a set
- *tasks* a list of task specifications, in which case the resource is
  classified as a "slot" or "shard," note that leaf resources of resource
  trees with no explicit slots are implicitly converted to slots and inherit
  their task definition from the nearest enclosing program

__NOTE__: All IDs/UUIDs MUST reference resources of the same type
      unless the resource type is Group.

### Task

A task MUST contain:
- *command* a command in the form of a string or list of tokens, if a list of
  tokens is used, it will be passed on as though to execvp

A task MAY contain:
- *tags* a key-value dictionary of arbitrary tags

### Edge

Usually edges are not inspected as vertices themselves, but when greater
precision is necessary, they may be specified in full form.

A link MUST contain:
- *from* the source node object, id or uuid, the link may represent this by
  being stored *in* the from object itself.
- *to* the destination node
- *type* the link type, the hardware hierarchy type is "with," any other type
  may be used to represent other hierarcies or graphs

A link MAY contain:
- *attributes* a key-value dictionary of extra attributes

## Usage

In order to make use of this hierarchy less onerous, a complete default tree
could be provided in the future.  The following proposes a default that might
be used for this purpose. 

```yaml
--- #!job
# each document is a job, which contains a list of programs
default-task: &def-task
      command: flux-broker
      count: 1
      range-type: per-slot #could also be total or others later
      affinity: bind
default-resource: &def-res #!resource
  - count: 1
    name: PU # Smallest allocatable unit
    allocate: exclusive #default when not specified is shared, innermost exclusive
default-program: &def-prog
    tasks: 
        - *def-task
    resources: # !program
        - <<: *def-shard
programs: #to support re-use, lists of lists are implicitly flattened
  - <<: *def-prog
```

To illustrate the process, a completely blank jobspec (literally ""), would
result in running a flux instance with a single broker on one PU in the
current cluster, bound to that PU.  Specifying "Node" would run an instance
with a single broker on a node, having overridden the `name` key of the
default resource.  The resulting tree having specified "Node" would be:

```yaml
programs:
    - resources:
          - range: 1
            name: Node
            allocate: exclusive
      tasks:
          command: flux-broker
          range: 1
          range-type: per-shard #could also be total or others later
          affinity: bind
```

Likewise, specifying just a partial program context, by providing a top level
object naming tags, or specifying the type of the object explicitly with the
`!program` tag or `ftype: program`, would allow one to just override the
command or range.  While not technically part of the specification of the
language, this cascading behavior is important for usability.

### Resource specifications

Resources in a jobspec of this kind are normally specified in terms of the
types and amounts required, expecting a scheduler or runner to concretize them
to physical resources later.  In order to specify explicit resource sets, for
RDL specification or explicit task launch for example, the resource name/range
is replaced with either a list of resource IDs or uuids.  For example, to
specify the hype cluster in this markup to match the `hype.lua` config:

```lua
uses "Node"

Hierarchy "default" {
    Resource{ "cluster", name = "hype",
    children = { ListOf{ Node,
                  ids = "201-354",
                  args = { name = "hype",
                           sockets = {"0-7", "8-15"},
                           memory_per_socket = 15000 }
                 },
               }
    }
}
```

One could write this resource specification:

```yaml
name: Cluster
id: hype
with>:
    - id-list: hype[201-354]
      name: Node
      with>:
          - Socket[2]>Memory[15000]MB>Core[8] 
            #note: unit, MB here, causes Memory to become a pool
```


