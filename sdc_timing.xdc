##  SDC (تعليمات ال timing Violation Fixed)

### Basic Clock Creation
### Syntax
# create_clock -name <clock_name> -period <period> [get_ports <port_name>]

### Examples
### Default Waveform
# 100 MHz clock (10ns period)
create_clock -name sys_clk -period 10.0 [get_ports clk]

### Custom Waveform (Non-50% Duty Cycle)
# 40% duty cycle: high for 4ns, low for 6ns
create_clock -name clk_40 -period 10.0 -waveform {0 4} [get_ports clk]

# 30% duty cycle: high for 3ns, low for 7ns
create_clock -name clk_30 -period 10.0 -waveform {0 3} [get_ports clk]

### Inverted Clock (Starts Low)
# Starts low, rises at 5ns, falls at 10ns (one period later)
create_clock -name clk_inv -period 10.0 -waveform {5 10} [get_ports clk_n]

### Multiple Independent Clocks
### Asynchronous Clocks
# Fast clock for processor
create_clock -name cpu_clk -period 2.0 [get_ports clk_cpu]

# Slow clock for peripherals
create_clock -name peri_clk -period 50.0 [get_ports clk_peri]

# Declare them asynchronous (no timing relationship)
set_clock_groups -asynchronous \-group {cpu_clk} \-group {peri_clk}

### Generated Clocks
### Clock Divider
# Primary clock
create_clock -name main_clk -period 10.0 [get_ports clk]

# Divided-by-2 clock
create_generated_clock -name div2_clk \
    -source [get_ports clk] \
    -divide_by 2 \
    [get_pins divider/Q]

### Clock Multiplier (PLL)
# Input reference clock
create_clock -name ref_clk -period 20.0 [get_ports ref_clk]

# PLL output (multiply by 4)
create_generated_clock -name pll_clk \
    -source [get_ports ref_clk] \
    -multiply_by 4 \
    [get_pins pll/clk_out]

### Clock Properties
### Clock Uncertainty
# Jitter and skew
set_clock_uncertainty -setup 0.2 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.1 [get_clocks sys_clk]

### Clock Latency
# Source latency (before clock tree)
set_clock_latency -source 0.5 [get_clocks sys_clk]

# Network latency (clock tree delay)
set_clock_latency 1.0 [get_clocks sys_clk]

### Clock Transition
# Clock edge slew rate
set_clock_transition 0.1 [get_clocks sys_clk]


### Virtual Clocks
# Virtual clock for external system
# لايوجد لها بين حقيقي في حته توليد الكلوك 
create_clock -name ext_sys_clk -period 8.0

# Input timing relative to virtual clock
set_input_delay -clock ext_sys_clk -max 2.0 [get_ports data_in]

# Output timing relative to virtual clock
set_output_delay -clock ext_sys_clk -max 1.5 [get_ports data_out]



### Syntax
# set_input_delay -clock <clock_name> [-max|-min] <delay> [get_ports <port_pattern>]

### Examples
# External device launches data with 3ns delay
set_input_delay -clock sys_clk -max 3.0 [get_ports data_in]

# Minimum delay (for hold check)
set_input_delay -clock sys_clk -min 1.0 [get_ports data_in]

### Applying to Multiple Ports
# All input data ports
set_input_delay -clock sys_clk -max 2.5 [get_ports data_in*]

# Specific list of ports
set_input_delay -clock sys_clk -max 2.0 [get_ports {addr[0] addr[1] addr[2]}]

# All inputs except clock
set_input_delay -clock sys_clk -max 2.0 [all_inputs]

### Different Delays for Rising and Falling
# Rising edge
set_input_delay -clock sys_clk -max 2.0 [get_ports data]

# Falling edge
set_input_delay -clock sys_clk -clock_fall -max 2.5 [get_ports data]


### Output Delays
### Syntax
# set_output_delay -clock <clock_name> [-max|-min] <delay> [get_ports <port_pattern>]

### Examples
# External device needs data 1.5ns before its clock edge
set_output_delay -clock sys_clk -max 1.5 [get_ports data_out]

# Minimum output delay (for hold)
set_output_delay -clock sys_clk -min 0.3 [get_ports data_out]

### Add vs. Set: Cumulative Delays
### Set (Default): Replaces previous value
set_input_delay -clock clk -max 2.0 [get_ports data]
set_input_delay -clock clk -max 3.0 [get_ports data] # Overrides to 3.0

### Add: Accumulates
set_input_delay -clock clk -max 2.0 [get_ports data]
set_input_delay -clock clk -max -add 1.0 [get_ports data] # Total = 3.0


### Load and Drive Specifications
### Output Load
set_load <capacitance> [get_ports <port_pattern>]

### Examples
# 50 fF load (typical board trace + input cap)
set_load 0.05 [get_ports data_out*]

# Different loads for different outputs
set_load 0.03 [get_ports control_signals[*]]
set_load 0.08 [get_ports high_cap_outputs[*]]

# Default load for all outputs
set_load 0.05 [all_outputs]

# Units: Typically picofarads (pF) or femtofarads (fF) depending on Liberty file units

### Input Load
set_driving_cell -lib_cell <cell_name> [get_ports <port_pattern>]

### Examples
# External chip drives with a medium-strength buffer
set_driving_cell -lib_cell BUF_X2 [get_ports data_in[*]]

# Weak driver (high impedance input)
set_driving_cell -lib_cell BUF_X1 [get_ports slow_inputs[*]]

# Strong driver (low impedance)
set_driving_cell -lib_cell BUF_X8 [get_ports fast_inputs[*]]

### Alternative: Direct Transition Time
# Specify input transition directly
set_input_transition 0.2 [get_ports data_in[*]]

### Load and Drive: Complete I/O Example
# ================================================
# Input Constraints
# ================================================
# External CPU drives our inputs with strong buffers
set_driving_cell -lib_cell BUF_X4 [all_inputs]

# Input timing from CPU datasheet
set_input_delay -clock sys_clk -max 3.0 [get_ports data_in[*]]
set_input_delay -clock sys_clk -min 1.0 [get_ports data_in[*]]

# ================================================
# Output Constraints
# ================================================
# Drive external SRAM (moderate capacitance)
set_load 0.06 [get_ports mem_addr[*]]
set_load 0.08 [get_ports mem_data[*]]

# Output timing per SRAM datasheet
set_output_delay -clock sys_clk -max 2.5 [get_ports mem_addr[*]]
set_output_delay -clock sys_clk -max 2.5 [get_ports mem_data[*]]


### Max and Min Delay Constraints
set_max_delay <delay> -from <from_list> -to <to_list>

### Use Cases:
### [1] Asynchronous Paths
# Async reset distribution: must arrive within 5ns
set_max_delay 5.0 -from [get_ports async_rst] -to [all_registers]

### [2] Combinational Paths (No Clocks)
# Pure combinational logic from input to output
set_max_delay 3.0 -from [get_ports combo_in] -to [get_ports combo_out]

### set_min_delay
set_min_delay <delay> -from <from_list> -to <to_list>

### Use Cases:
### [1] Hold Margin on Critical Paths
# Ensure at least 0.5ns delay (prevent hold violations)
set_min_delay 0.5 -from [get_ports fast_input] -to [get_registers]


### Multicycle Paths
set_multicycle_path <num_cycles> -setup|-hold -from <from> -to <to>

### Common Scenarios:
### [1] Slow Functional Units
# 32-cycle integer divider
set_multicycle_path 32 -setup -from [get_pins divider/*] \
    -to [get_pins result_reg/D]
set_multicycle_path 31 -hold -from [get_pins divider/*] \
    -to [get_pins result_reg/D]

### [2] Multi-Cycle State Machine
# State machine takes 4 cycles per state
set_multicycle_path 4 -setup -from [get_pins state_reg[*]/Q] \
    -to [get_pins state_reg[*]/D]
set_multicycle_path 3 -hold -from [get_pins state_reg[*]/Q] \
    -to [get_pins state_reg[*]/D]

### [3] Data Valid Enable Signal
# Data updates every 3 cycles (controlled by enable)
set_multicycle_path 3 -setup -from [get_pins data_reg[*]/Q]
set_multicycle_path 2 -hold -from [get_pins data_reg[*]/Q]

### Example
# Path can take 2 clock cycles
set_multicycle_path 2 -setup \
    -from [get_pins launch_ff/Q] \
    -to [get_pins capture_ff/D]

# Adjust hold check (1 cycle, not 2)
set_multicycle_path 1 -hold \
    -from [get_pins launch_ff/Q] \
    -to [get_pins capture_ff/D]


