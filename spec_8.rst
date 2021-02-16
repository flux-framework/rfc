.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_8.html

8/Flux Task and Program Execution Services
==========================================

-  Name: github.com/flux-framework/rfc/spec_8.rst

-  Editor: Mark grondona <mgrondona@llnl.gov>

-  State: raw


Language
--------

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in `RFC 2119 <http://tools.ietf.org/html/rfc2119>`__.


Goals
-----

A core service of Flux is to launch, monitor, and handle I/O for
distributed sets of tasks in order to execute a parallel workload.
A Flux workload can include further instances of Flux, to arbitrary
recursive depth. The goal of this RFC is to specify in detail the
services required to execute a Flux workload.


Terminology
-----------

-  **task** A process, and its child processes, threads and fibers,
   launched directly by flux and assigned a unique, zero origin,
   unsigned integer rank. This SHALL serve as the basic granularity
   of I/O aggregation and state tracking in Flux.

-  **task slot** A set of resources, which MAY be constrained by a container,
   each of which MUST be sufficient to run at least one task.

-  **program** A single unit of execution within a flux instance, defining
   the environment, initial working directory, arguments, IO handling,
   and granularity and placement of task slots for its child tasks.

-  **job** A synonym for *program*.

-  **program parameters** Data for a program that impacts how its tasks are
   executed. For example, arguments, environment, working directory.

-  **program specification** The language and/or API used to communicate
   program parameters to a Flux instance.

-  **program context** a per-program datastore in the enclosing instance
   where a program MAY store persistent state.

-  **instance** A set of Flux framework services running within a single
   communication domain  [RFC 3], that includes a capability to launch
   programs. A Flux instance is such a *program*.

-  **enclosing instance** The instance in which a program is running.

-  **task manager** A service provided by a Flux instance for the management,
   execution, and manipulation of tasks within a program.

-  **instance owner** The user on behalf of which a Flux instance is running.

-  **program frontend** A utility or service to run a program in the foreground.


Basic Execution Services of an Instance
---------------------------------------

A Flux instance SHALL offer basic services to start programs on behalf of users
that have access to the instance. Programs SHALL only be started on resources
to which the current Flux instance has been allocated.


Program Parameters
------------------

Program parameters accepted by a Flux instance SHALL be sufficient
to fully define creation, distribution, and environment of tasks
executed as part of the program. These parameters MAY include:

-  Arguments (MAY be per task)

-  Working directory (MAY be inherited from instance)

-  Environment

-  Limits

-  Task mapping

-  Dependencies on other programs

Program parameters SHALL be inherited where effective. For example,
the environment for a task within a program SHALL be inherited from
the parent program, and a program SHALL inherit its environment from
the program that created it. A mechanism to override inherited program
parameters SHALL be provided.

A Flux instance MUST support persistence of program parameters for normal
program execution.


Program specification
---------------------

The form in which program parameters and other program data are
communicated to a Flux instance is called the program specification.

The program specification is fully detailed in a future RFC, however
in this document it is suggested that the program specification have
at a minimum the following properties

-  scriptable interface

-  ability to specify task slots

-  ability to map tasks to task slots with arbitrary complexity

-  ability to describe dynamic program properties

-  optionally include binary data (e.g. include a tarball or other
   package format of executables, input data, etc.)


Scheduling Program Execution
----------------------------

.. sidebar:: FIXME

   Tom argues this section should be removed. I don’t really disagree…​

Programs SHALL be executed as scheduled by a Scheduler from the enclosing
instance, unless an *immediate* or *unscheduled* execution is requested.
It is RECOMMENDED that unscheduled program execution be restricted to
the instance owner.

When requesting *immediate* program execution, an explicit list of resources
on which to target the program MUST be supplied by the caller.

When submitting a *scheduled* program execution, a suitable description of
required resources for the program MUST be supplied by the caller, and
the scheduler of the enclosing instance SHALL be responsible for choosing
resources on which to execute the program.


Program Input/Output
--------------------

Execution services within a Flux instance SHALL have the ability to
direct standard input and output to and from tasks within a program.

If running under control of a frontend utility, standard output and stderr
SHALL be copied to the stdout/stderr of the front end program. The
IO MAY also be saved to another repository within the enclosing instance.

A Flux instance SHALL offer the ability to run a program without a
frontend command, and to continue running a program if the frontend
command is terminated unexpectedly. In this case, stdout and stderr
of the program MUST be saved in some form for later retrieval.

A Flux instance SHALL offer a method or methods to send stdin to
one or more tasks within an executing program. The contents of stdin
MAY be saved for later retrieval.


Initial Program (Program 1)
---------------------------

A newly created Flux instance SHALL support creation of an initial
program analogous to the init program on a UNIX system. The initial
program SHALL be any valid program including a single process
interactive shell or batch script.

A Flux instance SHALL complete and release resources upon exit
of the initial program.

Parameters of the initial program SHALL be set by the enclosing instance
as parent, and MAY include:

-  Environment and namespace such that enclosing instance is default
   Flux instance for all subprocesses

-  Credentials of the enclosing instance owner

-  Contain a proper subset of enclosing instance

The task slot on which to run the initial program MAY be influenced
by the program parameters of the instance.

The initial program of an instance MAY be used to further customize
the enclosing instance, e.g. by loading extra modules, spawning
initial programs, running initialization scripts and so on.


Bootstrap Mechanism
-------------------

All instances of Flux SHALL be started under a bootstrap mechanism.
The bootstrap mechanism SHALL provide the bare minimum
services required to provide the processes with their initial configuration
data and to assist them with network discovery.


Program Containers
------------------

Programs MAY be run in containers that restrict
program execution to resources assigned to the program. Instance
owners MAY OPTIONALLY run programs outside of any containment. Programs
run without such containment SHALL be bound by the container of the
enclosing instance.


Program States
--------------

.. sidebar:: FIXME

   Need to incorporate @dongahn’s state as used by Job Status and
   Control Module.

-  **empty**

-  **pending**

-  **starting**

-  **running**

-  **complete**

-  **growing**

-  **shrinking**


Program Interface
-----------------

.. sidebar:: FIXME

   @trws suggests we fully define here which interface and control
   methods are available in what contexts. Is there a different interface
   from within a program?

..

.. sidebar:: FIXME

   @dongahn would like to additionally address *sync*, *bind*, and *contain*

A Flux instance SHALL support at least the following program initiation
and control methods:

-  **new** Reserve a new program handle P. The handle P SHALL be
   considered to be an empty or reserved program. *new() → P*

-  **current_program** Get a program handle P for the program of the caller.

-  **allocate** Allocate resources R from the enclosing instance using
   a resource description Rdesc. *alloc(Rdesc) → R*

-  **grow** Grow a program P by resource set R. If the user U is not
   the instance owner, then R MUST be a resource set properly allocated
   from the enclosing instance. *grow(P, R)*

-  **map** Map a task or tasks description T onto program P. *map(T,P)*

-  **exec** Execute all pending tasks in program P.
   *exec(P)*

-  **shrink** Remove resource set R' from program *P*.
   Tasks within *P* will be constrained to the new resource set for *P*.
   If migration of a task to the new resource set is impossible, the
   task MAY be terminated, stopped, or hibernated.
   If *R' == R* then *P* becomes an empty program
   and all running tasks are terminated.

-  **wait** Wait on status changes in program P.

-  **signal** Send signals to all executing tasks in program P.

-  **terminate** Terminate program P and *wait* for completion.

-  **reap** Post-processing of the *program context* of a completed
   program by its enclosing instance.

Other methods MAY be built using these primitives. For instance, a
*run* or *launch* compound command may combine the *allocate*,
*new*, *grow*, *map*, and *exec* into a single interface.

A Flux instance SHALL support at least the following program information
methods:

-  **list** List all programs known to enclosing instance

-  **getinfo** List data for a program P. The data returned SHALL include
   all program parameters, all tasks and their states, etc.

Flux methods called by programs MUST interact with the enclosing
instance. Therefore, programs MUST first obtain their own program handle
in order to affect themselves with the methods above. Programs MAY have
the ability to call a subset of the above methods on sibling programs within
the same instance. The enclosing instance SHALL arbitrate these
calls based on security policy and ownership of the instance.

As a program, a Flux instance MAY utilize any of the methods above
as needed to make requests of its enclosing instance.
