.. github display
   GitHub is NOT the preferred viewer for this file. Please visit
   https://flux-framework.rtfd.io/projects/flux-rfc/en/latest/spec_13.html

13/Simple Process Manager Interface v1
######################################

.. highlight:: c

.. default-domain:: c

The MPI process manager interface (PMI) version 1 is a de-facto standard
API and wire protocol for communication between MPI runtimes and resource
managers. It was added to the MPICH2 MPI-2 reference implementation in
late 2001, and has since been widely implemented, but was not officially
standardized by the MPI Forum and has been only lightly documented.
This RFC is an attempt to document PMI-1 to guide developers of resource
managers that must support current and legacy MPI implementations.

.. list-table::
  :widths: 25 75

  * - **Name**
    - github.com/flux-framework/rfc/spec_13.rst
  * - **Editor**
    - Jim Garlick <garlick@llnl.gov>
  * - **State**
    - raw

Language
********

.. include:: common/language.rst

Related Standards
*****************

- :doc:`spec_12`

Goals
*****

-  Decrease coupling between process managers and MPI implementations by
   clarifying their "contract" for communication.

-  Document the PMI-1 application programming interface (API)

-  Document the PMI-1 wire protocol

-  Document compatibility issues between protocol versions.

-  Decrease the amount of research required to implement a process manager.

-  Identify which functions are optional, and under what circumstances.

PMI Versions
************

This document covers PMI 1.1 with a few notes about backwards
compatibility with earlier versions.

The PMI version 2 API is disjoint from version 1. The version 2
wire protocol builds on the same fundamental structures as version 1,
but includes incompatible operations. Clients and servers negotiate
the highest mutually supported protocol version, including across major
protocol versions. Apart from version negotiation and the common
fundamentals, PMI version 2 a different protocol and not covered here.

PMIx ("x" for exascale, from the OpenMPI community) is a separate effort
that is not covered here.

PMIX ("X" for extension), is a set of extensions to PMI-2. The PMIX
extensions are not covered here.

Overview
********

PMI was designed as an interface between process managers and parallel
programs, including, but not limited to, MPI runtimes. It has two main
parts, one part designed to assist with bootstrap activities that need
to take place inside :func:`MPI_Init`, and the other part designed to
support MPI-2’s dynamic process management features, such as
:func:`MPI_Comm_spawn`.

A newly-launched MPI process needs to find out (minimally) its rank,
the total number of ranks in the program, and network addresses of
other ranks. The rank and size can be trivially passed to the process
from the process manager via environment variables. Network addresses
could be assigned by the process manager and passed in a similar way,
but that would require the process manager to have intimate knowledge of
interconnects and the MPI implementation’s internal wire-up topologies.
To achieve a separation of concerns, the PMI designers wisely suggested
that the process manager only provide a generic mechanism for MPI
processes to exchange information.

This mechanism consists of a key value store (KVS). What one process
puts into the KVS can be read out by another process, after appropriate
synchronization. A simple collective barrier function provides this
synchronization. Once all processes have reached the barrier, all
data has been written, and can be read once processes are released
from the barrier.

Programs may access PMI-1 services provided by a process manager using
the PMI-1 wire protocol; a shared library providing the PMI-1 API
implemented using the PMI-1 wire protocol; or less flexibly, a shared
library providing the PMI-1 API implemented using a proprietary protocol.

Terminology
***********

Process manager
  The provider of PMI services. A resource manager MAY operate in the role
  of process manager.

Process group
  A parallel program, including but not limited to MPI programs.  It is
  the user of PMI services.  In this document *program* is used interchangeably
  process group.

process
  A UNIX process, in this context, a member of a process group or a program.

PMI library
  A shared library that provides the PMI-1 API.

Caveats
*******

Some deficiencies of PMI 1 are noted in the PMI-2 paper [#f6]_:

-  There is no mechanism to scope a key locally for a subset of processes.

-  PMI-1 is not thread safe. On a given PMI connection, only one request
   can be in flight concurrently.

-  There is no way for a program to access the PMI KVS of another cooperating
   program.

-  There is no mechanism for respawning processes when a fault occurs.

In addition, the lack of strong guidance from the MPI Forum has limited
acceptance of the PMI wire protocol and resulted in incomplete and
non-conforming PMI library implementations. This in turn has resulted
in stronger coupling between process managers and MPI implementations
than necessary.

Environment
***********

The process manager MAY use the UNIX environment to communicate basic
process group information to processes.

If the PMI wire protocol is offered, the process manager SHALL
set the following environment variables:

.. list-table::
   :header-rows: 1

   * - Variable
     - Description
   * - PMI_FD
     - file descriptor process SHALL use to communicate with process manager
   * - PMI_RANK
     - rank of this process within the program (zero-origin)
   * - PMI_SIZE
     - size of the program (number of ranks)
   * - PMI_SPAWNED
     - only set (to 1) if the program was created by :func:`PMI_Spawn_multiple`

Application Programming Interface
*********************************

Programs SHOULD NOT strongly bind to a particular process manager’s
PMI library, for example with rpath, as this complicates running a
compiled program under multiple process managers, especially if a
system includes process managers that use proprietary protocols.

To provide maximum interoperability, a PMI library SHOULD

-  implement the PMI-1 wire protocol

-  be named "libpmi"

-  have a shared library major version number of 0

-  provide all function signatures defined below

Functions tagged as "OPTIONAL" SHOULD be defined, but may be implemented
to return PMI_FAIL with no effect.

There is no defined mechanism to extend PMI-1 without inadvertently
coupling users of a extension to a PMI library and/or process manager,
therefore PMI libraries SHALL NOT implement functions not defined below.

Return Codes
============

All PMI-1 functions SHALL return one of the following integer values,
indicating the result of the operation:

.. list-table::
   :header-rows: 1
   :widths: 20 5 20

   * - Name
     - Value
     - Description
   * - PMI_SUCCESS
     - 0
     - operation completed successfully
   * - PMI_FAIL
     - -1
     - operation failed
   * - PMI_ERR_INIT
     - 1
     - PMI not initialized
   * - PMI_ERR_NOMEM
     - 2
     - input buffer not large enough
   * - PMI_ERR_INVALID_ARG
     - 3
     - invalid argument
   * - PMI_ERR_INVALID_KEY
     - 4
     - invalid key argument
   * - PMI_ERR_INVALID_KEY_LENGTH
     - 5
     - invalid key length argument
   * - PMI_ERR_INVALID_VAL
     - 6
     - invalid val argument
   * - PMI_ERR_INVALID_VAL_LENGTH
     - 7
     - invalid val length argument
   * - PMI_ERR_INVALID_LENGTH
     - 8
     - invalid length argument
   * - PMI_ERR_INVALID_NUM_ARGS
     - 9
     - invalid number of arguments
   * - PMI_ERR_INVALID_ARGS
     - 10
     - invalid args argument
   * - PMI_ERR_INVALID_NUM_PARSED
     - 11
     - invalid num_parsed length argument
   * - PMI_ERR_INVALID_KEYVALP
     - 12
     - invalid keyvalp argument
   * - PMI_ERR_INVALID_SIZE
     - 13
     - invalid size argument

Initialization
==============

.. function:: int PMI_Init (int *spawned)

Initialize the PMI library for this process. Upon success, the value
of :var:`spawned` (boolean) SHALL bet set to (1) if this process was created
by :func:`PMI_Spawn_multiple`, or (0) if not.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - initialization failed

.. function:: int PMI_Initialized (int *initialized)

Check if the PMI library has been initialized for this process.
Upon success, the the value of :var:`initialized` (boolean) SHALL be set to
(1) or (0) to indicate whether or not PMI has been successfully initialized.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to set the variable

.. function:: int PMI_KVS_Get_name_length_max (int *length)
.. function:: int PMI_KVS_Get_key_length_max (int *length)
.. function:: int PMI_KVS_Get_value_length_max (int *length)
.. function:: int PMI_Get_id_length_max (int *length)

Obtain the maximum length (including terminating NULL) of KVS name,
key, value, and id strings. Upon success, the PMI library SHALL
set the value of :var:`length` to the maximum name length for the requested
parameter.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to set the length

Notes:

-  Process Management in MPICH [#f1]_ recommends minimum lengths for
   name, key, and value of 16, 32, and 64, respectively.

-  :func:`PMI_Get_id_length_max` SHALL be considered an alias for
   :func:`PMI_KVS_Get_name_length_max`.

-  :func:`PMI_Get_id_length_max` was dropped from pmi.h [#f3]_ on 2011-01-28 in
   `commit f17423ef <https://github.com/pmodels/mpich/commit/f17423ef535f562bcacf981a9f7e379838962c6e>`__.

.. function:: int PMI_Finalize (void)

Finalize the PMI library for this process.

Errors:

-  PMI_FAIL - finalization failed

.. function:: int PMI_Abort (int exit_code, const char error_msg[])

Abort the process group associated with this process.
The PMI library SHALL print :var:`error_msg` to standard error, then exit
this process with with :var:`exit_code`. This function SHALL NOT return.

Process Group Information
=========================

.. function:: int PMI_Get_size (int *size)

Obtain the size of the process group to which the local process belongs.
Upon success, the value of :var:`size` SHALL be set to the size of the
process group.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to return the size

.. function:: int PMI_Get_rank (int *rank)

Obtain the rank (0…​size-1) of the local process in the process group.
Upon success, :var:`rank` SHALL be set to the rank of the local process.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to return the rank

.. function:: int PMI_Get_universe_size (int *size)

Obtain the universe size, which is the the maximum future size of the
process group for dynamic applications. Upon success, :var:`size` SHALL
be set to the rank of the local process.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to return the size

Notes:

-  See MPI-2 [#f2]_ section `5.5.1. Universe Size <https://www.mpi-forum.org/docs/mpi-2.0/mpi-20-html/node111.htm>`__.

.. function:: int PMI_Get_appnum (int *appnum)

Obtain the application number. Upon success, :var:`appnum` SHALL be set to
the application number.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to return the appnum

Notes

-  See MPI-2 [#f2]_ section `5.5.3. MPI_APPNUM <https://www.mpi-forum.org/docs/mpi-2.0/mpi-20-html/node113.htm>`__.

Local Process Group Information
===============================

.. function:: int PMI_Get_clique_ranks (int ranks[], int length)

Get the ranks of the local processes in the process group.
This is a simple topology function to distinguish between processes that can
communicate through IPC mechanisms (e.g., shared memory) and other network
mechanisms. The user SHALL set :var:`length` to the size returned by
:func:`PMI_Get_clique_size`, and :var:`ranks` to an integer array of that
length.  Upon success, the PMI library SHALL fill each slot of the array with
the rank of a local process in the process group.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_ERR_INVALID_LENGTH - invalid length argument

-  PMI_FAIL - unable to return the ranks

Notes:

-  This function returns the ranks of the processes on the local node.

-  The array must be at least as large as the size returned by
   :func:`PMI_Get_clique_size`.

-  This function was dropped from pmi.h [#f3]_ on 2011-01-28 in
   `commit f17423ef <https://github.com/pmodels/mpich/commit/f17423ef535f562bcacf981a9f7e379838962c6e>`__

-  The implementation should fetch the ``PMI_process_mapping`` value from the
   KVS and calculate the clique ranks (see below).

.. function:: int PMI_Get_clique_size (int *size)

Obtain the number of processes on the local node. Upon success, :var:`size`
SHALL be set to the number of processes on the local node.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to return the clique size

Notes:

-  This function was dropped from pmi.h [#f3]_ on 2011-01-28 in
   `commit f17423ef <https://github.com/pmodels/mpich/commit/f17423ef535f562bcacf981a9f7e379838962c6e>`__

-  The implementation should fetch the ``PMI_process_mapping`` value from the
   KVS and calculate the clique ranks (see below).

Key Value Store
===============

.. function:: int PMI_KVS_Put (const char kvsname[], const char key[], const char value[])

Put a key/value pair in a keyval space.
The user SHALL set :var:`kvsname` to the name returned from
:func:`PMI_KVS_Get_my_name`.  The user SHALL set :var:`key` and
:var:`value` to NULL terminated strings no longer (with NULL) than the sizes
returned by :func:`PMI_KVS_Get_key_length_max` and
:func:`PMI_KVS_Get_value_length_max` respectively.

Upon success, the PMI value SHALL be visible to other processes after
:func:`PMI_KVS_Commit` and :c:func:`PMI_Barrier` are called.

Errors:

-  PMI_ERR_INVALID_KVS - invalid kvsname argument

-  PMI_ERR_INVALID_KEY - invalid key argument

-  PMI_ERR_INVALID_VAL - invalid val argument

-  PMI_FAIL - put failed

Notes:

-  The function MAY complete locally.

-  All keys put to a keyval space SHALL be unique to the keyval space.

-  A key SHALL NOT be put more than once to a keyval space.

.. function:: int PMI_KVS_Commit (const char kvsname[])

Commit all previous puts to the keyval space. Upon success, all puts
since the last :func:`PMI_KVS_Commit` shall be stored into the specified
:var:`kvsname`.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - commit failed

Notes:

-  This function commits all previous puts since the last 'PMI_KVS_Commit()'
   into the specified keyval space.

-  It is a process local operation, thus in some implementations,
   it MAY have no effect and still return PMI_SUCCESS.

.. function:: int PMI_KVS_Get (const char kvsname[], const char key[], char value[], int length)

Get a key/value pair from a keyval space.
The user SHALL set :var:`kvsname` to the name returned from
:func:`PMI_KVS_Get_my_name`.  The user SHALL set :var:`length` to the
length of the :var:`value` array, which SHALL be no shorter than the length
returned by :func:`PMI_KVS_Get_value_length_max`.  The user SHALL set
:var:`key` to a NULL terminated string no longer (with NULL) than the size
returned by :func:`PMI_KVS_Get_key_length_max`.

Upon success, the PMI library SHALL fill :var:`value` with the value
associated the key.

Errors:

-  PMI_ERR_INVALID_KVS - invalid kvsname argument

-  PMI_ERR_INVALID_KEY - invalid key argument

-  PMI_ERR_INVALID_VAL - invalid val argument

-  PMI_ERR_INVALID_LENGTH - invalid length argument

-  PMI_FAIL - get failed

.. function:: int PMI_KVS_Get_my_name (char kvsname[], int length)
.. function:: int PMI_Get_kvs_domain_id (char kvsname[], int length)
.. function:: int PMI_Get_id (char kvsname[], int length)

This function returns the common keyval space for this process group.
The user SHALL set set :var:`length` to the length of the :var:`kvsname`
array, which SHALL be no shorter than the length returned by
:func:`PMI_KVS_Get_name_length_max`.

Upon success, the PMI library SHALL set :var:`kvsname` to a NULL terminated
string representing the keyval space.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_ERR_INVALID_LENGTH - invalid length argument

-  PMI_FAIL - unable to return the kvsname

Notes:

-  :var:`length` SHALL be greater than or equal to the length returned
   by :func:`PMI_KVS_Get_name_length_max`.

-  :func:`PMI_Get_kvs_domain_id` and :c:func:`PMI_Get_id` SHALL be considered
   an alias for :func:`PMI_KVS_Get_my_name`.

-  :func:`PMI_Get_kvs_domain_id()` and :c:func:`PMI_Get_id()` were dropped
   from pmi.h [#f3]_ on 2011-01-28 in `commit f17423ef <https://github.com/pmodels/mpich/commit/f17423ef535f562bcacf981a9f7e379838962c6e>`__.

.. function:: int PMI_Barrier (void)

This function is a collective call across all processes in the process group
the local process belongs to. The PMI library SHALL attempt to block until
all processes in the process group have entered the barrier call, or an
error occurs.

Errors:

-  PMI_FAIL - barrier failed

Notes:

-  This operation is the only collective defined for PMI-1.

-  Some implementations MAY piggyback a KVS data exchange on the barrier
   operation internally.

-  The barrier operation MUST be usable as a generic synchronization mechanism,
   without requiring KVS data to be queued for exchange.

.. function:: int PMI_KVS_Create (char kvsname[], int length)
.. function:: int PMI_KVS_Destroy (const char kvsname[]);
.. function:: int PMI_KVS_Iter_first (const char kvsname[], char key[], int key_len, char val[], int val_len)
.. function:: int PMI_KVS_Iter_next (const char kvsname[], char key[], int key_len, char val[], int val_len)

Notes:

-  These functions are OPTIONAL.

-  Dropped from pmi.h [#f3]_ on 2011-01-28 in
   `commit f17423ef <https://github.com/pmodels/mpich/commit/f17423ef535f562bcacf981a9f7e379838962c6e>`__,

Dynamic Process Management
==========================

.. code:: c

   typedef struct {
       const char * key;
       char * val;
   } PMI_keyval_t;

.. function:: int PMI_Spawn_multiple (int count, const char *cmds[], const char **argvs[], const int maxprocs[], const int info_keyval_sizesp[], const PMI_keyval_t *info_keyval_vectors[], int preput_keyval_size, const PMI_keyval_t preput_keyval_vector[], int errors[])

This function spawns a set of processes into a new process group.
:var:`count` refers to the size of the array parameters :var:`cmd`,
:var:`argvs`, :var:`maxprocs`, :var:`info_keyval_sizes` and
:var:`info_keyval_vectors`.  :var:`preput_keyval_size` refers to the size
of the :var:`preput_keyval_vector` array.

:var:`preput_keyval_vector` contains keyval pairs that will be put in the
keyval space of the newly created process group before the processes
are started.

The :var:`maxprocs` array specifies the desired number of processes
to create for each :var:`cmd` string. The actual number of processes
may be less than the numbers specified in :var:`maxprocs`. The acceptable
number of processes spawned may be controlled by "soft" keyvals in
the info arrays.

Environment variables may be passed to the spawned processes through PMI
implementation specific :var:`info_keyval` parameters.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - spawn failed

Notes:

-  This function is OPTIONAL in process managers that do not support
   dynamic process management.

-  The "soft" option is specified by mpiexec in the MPI-2 standard.

-  See MPI-2 [#f2]_ section `5.3.5.1. Manager-worker Example, Using MPI_SPAWN. <https://www.mpi-forum.org/docs/mpi-2.0/mpi-20-html/node98.htm>`__

.. function:: int PMI_Publish_name (const char service_name[], const char port[])
.. function:: int PMI_Unpublish_name (const char service_name[])
.. function:: int PMI_Lookup_name (const char service_name[], char port[])

Publish/unpublish/lookup a name.

Errors:

-  PMI_ERR_INVALID_ARG - invalid argument

-  PMI_FAIL - unable to publish service

Notes:

-  These functions are OPTIONAL in process managers that do not support
   dynamic process management.

-  See MPI-2 [#f2]_ section `5.4.4. Name Publishing <https://www.mpi-forum.org/docs/mpi-2.0/mpi-20-html/node104.htm>`__.

.. function:: int PMI_Parse_option (int num_args, char *args[], int *num_parsed, PMI_keyval_t **keyvalp, int *size)
.. function:: int PMI_Args_to_keyval (int *argcp, char *((*argvp)[]), PMI_keyval_t **keyvalp, int *size)
.. function:: int PMI_Free_keyvals (PMI_keyval_t keyvalp[], int size)
.. function:: int PMI_Get_options (char *str, int *length)

Notes:

-  These functions are OPTIONAL.

-  These functions were dropped from pmi.h [#f3]_ on 2009-05-01 in
   `commit 52c462d <https://github.com/pmodels/mpich/commit/52c462d2be6a8d0720788d36e1e096e991dcff38>`__

Wire Protocol
*************

The reference implementation of the PMI-1.1 wire protocol is the MPICH
Hydra [#f4]_ process manager.

The protocol is comprised of request and response messages.
All messages SHALL be terminated with a newline.
Messages SHALL consist of a series of key=value tuples, as defined below.

Only the client (process) SHALL send request messages. Only the server
(process manager) SHALL send response messages. The client and server
exchange request and response messages in lock-step.

The PMI-1.1 wire protocol is defined below in ABNF form.
For maximum interoperability, a message parser SHOULD allow

-  key=value tuples to appear out of order within a message

-  additional white space to appear between tuples

-  additional keys to be present

Connection
==========

If the wire protocol is offered, the process manager SHALL "pre-connect"
a file descriptor, arrange for the file descriptor to be inherited by
the process, and pass its number in the PMI_FD environment variable
at process launch time.

Version Negotiation
===================

The client SHALL send the init request first, with the highest version
of PMI supported by the client. The server SHALL respond with the
version of PMI that will be used for this connection. The client SHALL NOT
send other commands until the init operation has completed.

Error Handling
==============

All responses MAY include an "rc" key.
On error, the "rc" key SHALL be set to a nonzero value.
On success, the "rc" key MAY be set to zero, or it may be omitted.

Some responses MAY include a "msg" key.
On error, the "msg" key MAY be set to an error message.
On success, the "msg" key MAY be set to "success", or it may be omitted.

If a protocol error occurs, the detecting side SHALL immediately close
the connection and abort the program. IT SHOULD log the message so that
the problem can be tracked down.

Spawn Operation
===============

The spawn request consists of multiple newline-terminated messages.
These messages SHALL NOT be interspersed with messages for other operations.

The spawn operation passes zero or more arguments, zero or more "preput"
elements, and zero or more "info" elements. The numbered indices of these
elements SHALL begin with zero and increase monotonically.

Protocol Definition
===================

.. code-block:: ABNF

   PMI1            = C:init      S:init
                   / C:maxes     S:maxes
                   / C:abort     S:abort
                   / C:finalize  S:finalize
                   / C:universe  S:universe
                   / C:appnum    S:appnum
                   / C:put       S:put
                   / C:kvsname   S:kvsname
                   / C:barrier   S:barrier
                   / C:get       S:get
                   / C:publish   S:publish
                   / C:unpublish S:unpublish
                   / C:lookup    S:lookup
                   / C:spawn     S:spawn

   ; Initialization

   C:init          = "cmd=init" SP "pmi_version=" uint SP "pmi_subversion=" uint LF
   S:init          = "cmd=response_to_init"
                     [SP "rc=" int]
                     [SP "pmi_version=" uint SP "pmi_subversion=" uint]
                     LF

   C:maxes         = "cmd=get_maxes" LF
   S:maxes         = "cmd=maxes"
                     [SP "rc=" int]
                     [SP "kvsname_max=" uint SP "keylen_max=" uint SP "vallen_max=" uint]
                     LF

   C:abort         = "cmd=abort" LF
   S:abort         = LF

   C:finalize      = "cmd=finalize" LF
   S:finalize      = "cmd=finalize_ack"
                     [SP "rc=" int]
                     LF

   ; Process Group Information

   C:universe      = "cmd=get_universe_size" LF
   S:universe      = "cmd=universe_size"
                     [SP "rc=" int]
                     [SP "size=" uint]
                     LF

   C:appnum        = "cmd=get_appnum" LF
   S:appnum        = "cmd=appnum"
                     [SP "rc=" int]
                     [SP "appnum=" uint]
                     LF

   ; Key Value Store

   C:put           = "cmd=put" SP "kvsname=" word SP "key=" word SP "value=" string LF
   S:put           = "cmd=put_result"
                     [SP "rc=" int]
                     LF

   C:kvsname       = "cmd=get_my_kvsname" LF
   S:kvsname       = "cmd=my_kvsname"
                     [SP "rc=" int]
                     [SP "kvsname=" word]
                     LF

   C:barrier       = "cmd=barrier_in" LF
   S:barrier       = "cmd=barrier_out"
                     [SP "rc=" int]
                     LF

   C:get           = "cmd=get" SP "kvsname=" word SP "key=" word LF
   S:get           = "cmd=get_result"
                     [SP "rc=" int]
                     [SP "value=" string]
                     LF

   ; Dynamic Process Management

   C:publish       = "cmd=publish_name" SP "service=" word SP "port=" word LF
   S:publish       = "cmd=publish_result"
                     [SP "rc=" int]
                     [SP "msg=" string]
                     LF

   C:unpublish     = "cmd=unpublish_name" SP "service=" word LF
   S:unpublish     = "cmd=unpublish_result"
                     [SP "rc=" int]
                     [SP "msg=" string]
                     LF

   C:lookup        = "cmd=lookup_name" SP "service=" word LF
   S:lookup        = "cmd=lookup_result"
                     [SP "rc=" int]
                     SP ["port=" word / "msg=" string ]
                     LF

   C:spawn         = "mcmd=spawn" LF
                     "nprocs=" uint LF
                     "execname=" string LF
                     "totspawns=" uint LF
                     "spawnssofar=" uint LF
                     *["arg" int "=" string LF]
                     "argcnt=" uint LF
                     "preput_num=" uint LF
                     *["preput_key_" uint "=" word LF "preput_val_" uint "=" string LF]
                     "info_num=" uint LF
                     *["info_key_" uint "=" string LF "info_val_" uint "=" string LF]
                     "endcmd" LF
   S: spawn        = "cmd=spawn_result"
                     [SP "rc=" int]
                     [SP "errcodes=" intlist]
                     LF

   ; macros

   intlist         = int *["," int]                ; comma-delimited integers
   word            = 1*(%x21-3C %x3E-7E)           ; visible char minus =
   string          = 1*(SP HTAB VCHAR)             ; visible char plus tab, space
   int             = *1("+" "-") uint              ; signed integer
   uint            = 1*DIGIT                       ; unsigned integer

Back Compatibility
==================

Earlier versions of the PMI-1 wire protocol did not include the init
operation in which versions are exchanged. Protocol operations that
were culled in PMI 1.1 are not covered here.

Local Process Group Information
*******************************

The process manager SHALL provide the local process group information
to programs via the KVS under the "PMI_process_mapping" key.  It MAY be
used by MPI to determine which process ranks are co-located on a given node.

The value SHALL consist of a vector of "blocks", where a block is a
3-tuple of starting node id, number of nodes, and number of processes per
node, in the following format, expressed in ABNF:

.. code-block:: ABNF

   PMI_process_mapping = "(vector," blocklist ")"

   block               = "(" uint "," uint "," uint ")" ; 3-tuple: (nodeid,nnodes,ppn)
   blocklist           = block *["," block]             ; comma delimited blocks

   uint                = 1*DIGIT                        ; unsigned integer


.. list-table:: PMI_process_mapping examples
   :header-rows: 1

   * - nnodes*ppn
     - block
     - cyclic
   * - 2*2
     - (vector,(0,2,2))
     - (vector,(0,2,1),(0,2,1))
   * - 2*4
     - (vector,(0,2,4))
     - (vector,(0,2,1),(0,2,1),(0,2,1),(0,2,1))
   * - 2*2 + 2*4
     - (vector,(0,2,2),(2,2,4))
     - (vector,(0,4,1),(0,4,1),(2,2,1),(2,2,1))
   * - 4096*256
     - (vector,(0,4096,256))
     - *long string*

If the process mapping value is too long to fit in a KVS value, the process
manager SHALL return a value consisting of an empty string, indicating that
the mapping is unknown.

References
**********

.. [#f1] `Process Management in MPICH <https://github.com/pmodels/mpich/blob/main/doc/wiki/notes/pm.md#notes>`__

.. [#f2] `MPI-2: Extensions to the Message-Passing Interface <https://www.mpi-forum.org/docs/mpi-2.0/mpi-20-html/mpi2-report.html>`__

.. [#f3] `MPICH canonical pmi.h header <https://github.com/pmodels/mpich/blob/94b1cd6f060cafbf68d6d83ea551a8bcc8fcecd4/src/pmi/include/pmi.h>`__

.. [#f4] `MPICH simple PMI implementation <https://github.com/pmodels/mpich/tree/94b1cd6f060cafbf68d6d83ea551a8bcc8fcecd4/src/pmi/simple>`__

.. [#f5] `SLURM PMI-1 implementation <https://github.com/SchedMD/slurm/blob/ba603812b947f14c1aba7adb220258feb7960001/src/api/slurm_pmi.c>`__

.. [#f6] `PMI: A Scalable Parallel Process-Management Interface for Extreme-Scale Systems <https://www.mcs.anl.gov/papers/P1760.pdf>`__, P. Balaji et al, EuroMPI Proceedings, 2010.
