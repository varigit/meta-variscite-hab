# Overrides for HAB
OVERRIDES:append:mx8m-generic-bsp:hab = ":hab4"

# Select signed target based on device
SIGNED_TARGET:mx8m-generic-bsp:hab = "flash_lpddr4_ddr4_evk"
SIGNED_TARGET:mx8mp-generic-bsp:hab = "flash_evk"
