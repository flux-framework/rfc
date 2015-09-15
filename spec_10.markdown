## Glossary:

This is a partial list that assumes knowledge of the flux terms defined in
RFC#8, some terms from that document are extended below to include their
definition in a job specification (jobspec) context.


- **Group:** A logical resource type used for adding information to the
  resource graph where a resource is unavailable.
- **Id-List:** A possibly-condensed name/id set, following the semantics of a
  hostlist
- **Link:** Conceptually every specification is a directed graph of nodes and
  edges.  *Links* represent the edges, and consist of a source, destination,
  type and tags.  Links from root to child `(cluster->Rack->Node...)` of type
  "with" form the hardware tree, and can be assumed to be directed downward.
- **Resource:** A single resource node, consisting of either: a resource
  type/name and range; or an id-list.  Each resource may optionally contain
  tags and *links* to other resources.
- **Slot/Shard:** A resource with an associated task. The leaf-resources in a
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


## TLDR

There are two languages in here, but they are both usable in both places.
Here are common case examples in the long and short forms.

### Run a flux instance on one Node

Long:

```yaml
Node
```

Short: `Node`

### Run an instance on between 9 and 300 nodes, allowing only counts which are cubes of 9

Long:

```yaml
Node[9:300:^3]
```

Short: why?

### Run `hostname` 20 times, 5 each on four nodes

Long:

```yaml
tasks: #program-level default inherited by slots
  - command: hostname
    range: 5
    # range-type: per-slot # already the default
resources:
  - name: Node
    range: 4 #leaf-level is a slot, inherits task
```

Short: `Node[4]?tasks:{"command":"hostname"}[5]`

CLI version: `-r 'Node[4]' -t 5 hostname`

### 11 tasks, one node, first 10 using one core and 4G of RAM for `read-db`, last using 6 cores and 24G of RAM for `db`

Generally, the author would recommend using the long-form or a submission
script for this, but in case one wants to do it...

Long:

```yaml
resources:
    - name: Node
      with>:
        - name: Group
          tasks: 
              command: read-db
              range: 10
          with>: 
            - Core
            - name: Memory
              range: 4
              range-unit: G
        - name: Group
          tasks: db
          with>:
            - name: Core
              range: 6
            - name: Memory
              range: 24
              range-unit: G
```

Medium:

```yaml
resources:
    - name: Node
      with>:
        - name: Group
          tasks: 
            command: read-db
            range: 10
          with>: 
            - Core
            - Memory[4]G
        - name: Group
          tasks: db
          with>:
            - Core[6]
            - Memory[24]G
```

Short: `Node(>Group(?tasks:{"command":"read-db","range":"[10]"}, >Core, >Memory[4]G),>Group(?tasks:db, >Core[6], >Memory[24]G))`
Short with backref and inward links: `Node=n1, @n1>Memory[4]G(>Core,?tasks:{"command":"read-db","range":"[10]"}), @n1>Memory[24]G?tasks:{"command":"db"}>Core[6]`

### Crazy example from OAR

"ask for 1 core on 2 nodes on the same cluster with 4096 GB of memory and Infiniband 10G + 1 cpu on 2 nodes on the same switch with bicore processors for a walltime of 4 hours"

```yaml
resources:
    - name: Cluster
      with>:
        - name: Node
          range: 2
          with>:
            - Memory[4096]GB
            - InfiniBand10G
        - Switch>Node[2]>Core
walltime: 4h
```

Or short: `Cluster(>Node[2](>Memory[4096]GB,>InfiniBand10G),>Switch>Node[2]>Core)`

Walltime being separate.

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
- *tags* a list of zero or more tags
- *dependencies* a list of zero or more dependencies, when no dependencies
  exist, a per-job logical dependency can be assumed

### Resource

A resource node MUST contain:
- One of:
    - *name/type* and *range*, where the range may default to 1 OR
    - *id-list* of the hostlist form representing the unique IDs of the
      constituent resources OR
    - *uuid-list* a list of uuids, referencing all constituent resources

A resource MAY contain:
- *links* a list of links to other resources or nodes generally, in or out, of
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

### Link

Usually links are not inspected as nodes themselves, but when greater
precision is necessary, they may be specified in full form.

A link MUST contain:
- *from* the source node object, id or uuid, the link may represent this by
  being stored *in* the from object itself.
- *to* the destination node
- *type* the link type, the hardware hierarchy type is "with," any other type
  may be used to represent other hierarcies or graphs

A link MAY contain:
- *tags* a key-value dictionary of extra attributes

## Short-form

To reduce typing, and make it possible to use this on the command line without
losing one's mind, a short-form syntax is also proposed.  The EBNF grammar is
currently approximately as follows:

```ebnf
(* Range *)
range-min = numeric
range-max = numeric
range-stride-op = "*", "+", "-", "^"
range-stride-num = numeric
range = "[", range-min, [ ":", range-max, [ ":", [range-stride-op], range-stride-num ] ], "]"
range-unit = ident (* Unit to apply to the range, used in resource to denote
                      pools, and in queries to denote a unit to extract from the pool,
                      such as MB, GB or MBps *)

(* Link *)
with-link-out = ">"
with-link-in = ">"
link-type = ident | quoted_string
link-body = "-", [link-type], [range], "-"
typed-link-in = ">", link-body, ">"
typed-link-out = "<", link-body, "<"
typed-link-omni = "<", link-body, ">"
link-target = resource
link = (with-link-in
      |with-link-out
      |typed-link-in
      |typed-link-out
      |typed-link-omni ) , link-target

(* Task *)
command = ident | quoted_string | '[' , yaml_list , ']' (* double braces *)
task = '$', [ command ], [ range ] (* Per-shard range only for now *)

(* Resource *)
id-list = { ident | hostlist-ident } 
id-definition = "=", ident
tag-key = ident | quoted_string
tag-value = ident | quoted_string | yaml_block
attribute-assignment = "?", tag-key, [ ":", tag-value ]
attribute = link | attribute-assignment
attribute-list = [task], attribute | "(", { attribute | task, "," } , ")"
resource-type = ident | quoted_string (* any resource type *)
resource = (resource-type, [( range, [ range-unit ] | id-definition)] 
            |  "@", id-list) , [attribute-list]
```

## Usage

In order to make use of this hierarchy less onerous,
a complete default tree is provided.  If a jobspec contains only lower levels,
they will override values in the default to form a full jobspec.  That default
jobspec is currently this:

```yaml
--- #!job
# each document is a job, which contains a list of programs
default-task: &def-task
      command: flux-broker
      range: 1
      range-type: per-shard #could also be total or others later
      affinity: bind
default-resource: &def-res #!resource
  - range: 1
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


