class ifx_dig_test_filter_both extends ifx_dig_testbase;

    `uvm_component_utils(ifx_dig_test_filter_both)


    // Test variables
    int filter_list[$]; // contains the indexes of the filters to be tested


    function new(string name = "ifx_dig_test_filter_both", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        `TEST_INFO("Run phase started")
    endtask

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);

        // TODO: drive reset
        drive_reset(0, 1, 5);
        
        `TEST_INFO("Main phase started")

        // create a random order of the filters to be tested
        for(int ifilt = 1; ifilt <= `FILT_NB; ifilt++) begin
            filter_list.push_back(ifilt);
        end
        filter_list.shuffle();


        // go through the filters and test them
        foreach(filter_list[ifilt]) begin

            `TEST_INFO($sformatf("Testing filter: %0d. Configure randomly the filter, except the filter type and interrupt enable", filter_list[ifilt]))
            configure_filter(
                .filt_idx(filter_list[ifilt]),
                .filter_type(FILT_BOTH)
                //.int_en(1) // enable interrupt - to ensure IRQ responds to the filter
                // .wd_rst(FILT_ASYNC_RESET), // by not configuring the reset type, the default will be random
                // .window_size(2) // by not configuring the window size, the default will be random
            );


            `TEST_INFO($sformatf("Drive an invalid pulse length on filter: %0d", filter_list[ifilt]))
            // drive a pulse on the filter - using the sequence created already in the testbase
            pin_filter_generic_seq.drive_type = FILT_DRV_INVALID;
            pin_filter_generic_seq.filt_edge  = FILT_FALL_EDGE;
            pin_filter_generic_seq.driving_edge_auto_select  = 1;
            pin_filter_generic_seq.start(dig_env.v_seqr.p_pin_filter_uvc_seqr[filter_list[ifilt] - 1]); // send the sequence of the specific filter sequencer
            `WAIT_NS($urandom_range(50,100))                                                            // let status update

            read_filter_status(0);// read all status registers
            clear_filter_status(filter_list[ifilt]);
            `WAIT_NS(100) // space between pulses


            `TEST_INFO($sformatf("Drive a valid pulse length on filter: %0d", filter_list[ifilt]))
            // TODO: drive a valid pulse on the filter using the ifx_dig_pin_filter_uvc_pulse_sequence
            pin_filter_valid_pulse_seq.start(dig_env.v_seqr.p_pin_filter_uvc_seqr[filter_list[ifilt] - 1]);

            read_filter_status(0);// read all status registers
            clear_filter_status(filter_list[ifilt]); //nu e necesar, noi aveam deja clear dupa citire
            `WAIT_NS(100) // space between pulses

        end

        `TEST_INFO("\n\n\nPrinting Coverage results\n\n\n")
        `TEST_INFO($sformatf("\ncg_filter_ctrl coverage is = %f\n", dig_env.scoreboard.cg_filter_ctrl.get_coverage()))
        `TEST_INFO($sformatf("\ncg_int_status_read coverage is = %f\n", dig_env.scoreboard.cg_int_status_read.get_coverage()))
        phase.drop_objection(this);
    endtask

endclass