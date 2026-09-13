/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Hamming(87,80) single-error-correcting code plus one extra overall
 * parity bit (SECDED - single error correction, double error detection),
 * applied to the 80-bit (10 byte) payload of the HOST<->CLIENT frames.
 *
 * Why: the frame protocol had no error detection at all - a single bit
 * flip on the board-to-board UART wire (an unshielded jumper between two
 * independently powered/clocked boards) silently corrupted the game
 * state with no way to tell, which matches the reported "works, then
 * randomly freezes/garbles" CLIENT symptom. This adds one extra byte to
 * each frame so the receiver can detect a corrupted frame and, for a
 * single flipped bit (the common case on a noisy link), correct it in
 * place instead of committing garbage or dropping out of sync.
 *
 * Data bits are numbered 1..87, skipping the 7 positions that are a
 * power of two (1,2,4,8,16,32,64) - those are reserved for the 7 Hamming
 * parity bits themselves, same as in the standard Hamming code. The
 * extra byte sent on the wire is {overall_parity, ham_parity[6:0]}.
 */
package hamming_secded_pkg;

    // HAM_MASKk[i] = 1 iff the i-th payload bit (i=0..79) sits at a
    // Hamming position whose bit k is set - i.e. HAM_MASKk selects
    // exactly the payload bits that parity bit k must cover.
    localparam logic [79:0] HAM_MASK0 = 80'hAAAAAB55555556AAAD5B;
    localparam logic [79:0] HAM_MASK1 = 80'hCCCCCD9999999B33366D;
    localparam logic [79:0] HAM_MASK2 = 80'hF0F0F1E1E1E1E3C3C78E;
    localparam logic [79:0] HAM_MASK3 = 80'h00FF01FE01FE03FC07F0;
    localparam logic [79:0] HAM_MASK4 = 80'hFF0001FFFE0003FFF800;
    localparam logic [79:0] HAM_MASK5 = 80'h000001FFFFFFFC000000;
    localparam logic [79:0] HAM_MASK6 = 80'hFFFFFE00000000000000;

    function automatic logic [6:0] ham_parity(input logic [79:0] payload);
        ham_parity[0] = ^(payload & HAM_MASK0);
        ham_parity[1] = ^(payload & HAM_MASK1);
        ham_parity[2] = ^(payload & HAM_MASK2);
        ham_parity[3] = ^(payload & HAM_MASK3);
        ham_parity[4] = ^(payload & HAM_MASK4);
        ham_parity[5] = ^(payload & HAM_MASK5);
        ham_parity[6] = ^(payload & HAM_MASK6);
    endfunction

    // Parity byte to append to an 80-bit payload before sending it.
    function automatic logic [7:0] hamming_encode(input logic [79:0] payload);
        logic [6:0] p;
        p = ham_parity(payload);
        hamming_encode = {(^payload) ^ (^p), p};
    endfunction

    // Maps a non-zero, non-power-of-two syndrome (3..87) to the payload
    // bit it points at (0..79). Only used when a single-bit error has
    // been confirmed to sit in the data, not in a parity bit.
    function automatic int flip_index(input logic [6:0] synd);
        case (synd)
            3: flip_index = 0;    5: flip_index = 1;    6: flip_index = 2;
            7: flip_index = 3;    9: flip_index = 4;    10: flip_index = 5;
            11: flip_index = 6;   12: flip_index = 7;   13: flip_index = 8;
            14: flip_index = 9;   15: flip_index = 10;  17: flip_index = 11;
            18: flip_index = 12;  19: flip_index = 13;  20: flip_index = 14;
            21: flip_index = 15;  22: flip_index = 16;  23: flip_index = 17;
            24: flip_index = 18;  25: flip_index = 19;  26: flip_index = 20;
            27: flip_index = 21;  28: flip_index = 22;  29: flip_index = 23;
            30: flip_index = 24;  31: flip_index = 25;  33: flip_index = 26;
            34: flip_index = 27;  35: flip_index = 28;  36: flip_index = 29;
            37: flip_index = 30;  38: flip_index = 31;  39: flip_index = 32;
            40: flip_index = 33;  41: flip_index = 34;  42: flip_index = 35;
            43: flip_index = 36;  44: flip_index = 37;  45: flip_index = 38;
            46: flip_index = 39;  47: flip_index = 40;  48: flip_index = 41;
            49: flip_index = 42;  50: flip_index = 43;  51: flip_index = 44;
            52: flip_index = 45;  53: flip_index = 46;  54: flip_index = 47;
            55: flip_index = 48;  56: flip_index = 49;  57: flip_index = 50;
            58: flip_index = 51;  59: flip_index = 52;  60: flip_index = 53;
            61: flip_index = 54;  62: flip_index = 55;  63: flip_index = 56;
            65: flip_index = 57;  66: flip_index = 58;  67: flip_index = 59;
            68: flip_index = 60;  69: flip_index = 61;  70: flip_index = 62;
            71: flip_index = 63;  72: flip_index = 64;  73: flip_index = 65;
            74: flip_index = 66;  75: flip_index = 67;  76: flip_index = 68;
            77: flip_index = 69;  78: flip_index = 70;  79: flip_index = 71;
            80: flip_index = 72;  81: flip_index = 73;  82: flip_index = 74;
            83: flip_index = 75;  84: flip_index = 76;  85: flip_index = 77;
            86: flip_index = 78;  87: flip_index = 79;
            default: flip_index = -1; // power-of-two syndrome: hit a parity bit, not data
        endcase
    endfunction

    // status: 0 = clean, 1 = corrected (or a parity bit itself was hit -
    // data untouched either way), 2 = uncorrectable (frame must be
    // dropped). Bits [81:80] = status, [79:0] = corrected payload.
    function automatic logic [81:0] hamming_decode(
        input logic [79:0] payload,
        input logic [7:0] parity_byte
    );
        logic [6:0] synd;
        logic overall_bad;
        logic [79:0] corrected;
        logic [1:0] status;
        int idx;

        synd = ham_parity(payload) ^ parity_byte[6:0];
        overall_bad = (^payload) ^ (^parity_byte);
        corrected = payload;

        if(synd == 7'b0 && !overall_bad) begin
            status = 2'd0;
        end
        else if(synd != 7'b0 && overall_bad) begin
            idx = flip_index(synd);
            if(idx >= 0) begin
                corrected[idx] = ~corrected[idx];
            end
            status = 2'd1;
        end
        else if(synd != 7'b0 && !overall_bad) begin
            status = 2'd2;
        end
        else begin
            status = 2'd1; // only the overall-parity bit itself was hit
        end

        hamming_decode = {status, corrected};
    endfunction

endpackage
