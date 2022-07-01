Data Quality Rules :

    1. Unless the Screened bit is set, no other bits can be set.

    2. Unused bits (22, 24, 27-31, 32+) must be reset (zero).

    3. The Okay, Missing, Questioned and Rejected bits are mutually
       exclusive.

    4. No replacement cause or replacement method bits can be set unless
       the changed (different) bit is also set, and if the changed (different)
       bit is set, one of the cause bits and one of the replacement
       method bits must be set.

    5. Replacement Cause integer is in range 0..4.

    6. Replacement Method integer is in range 0..4

    7. The Test Failed bits are not mutually exclusive (multiple tests can be
       marked as failed).

Bit Mappings :

         3                   2                   1
     2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1

     P - - - - - T T T T T T T T T T T M M M M C C C D R R V V V V S
     |           <---------+---------> <--+--> <-+-> | <+> <--+--> |
     |                     |              |      |   |  |     |    +------Screened T/F
     |                     |              |      |   |  |     +-----------Validity Flags
     |                     |              |      |   |  +--------------Value Range Integer
     |                     |              |      |   +-------------------Different T/F
     |                     |              |      +---------------Replacement Cause Integer
     |                     |              +---------------------Replacement Method Integer
     |                     +-------------------------------------------Test Failed Flags
     +-------------------------------------------------------------------Protected T/F
