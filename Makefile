INPUT := bin/fw.img.full.bin
# SECTIONS := 0x10700000 0x10800000 0x8120000 0x5000000 0x5100000 0x8140000 0x4000000
# BSS_SECTIONS := 0x10835000 0x5074000 0x8150000
# Only enable wupserver for now
SECTIONS := 0x5000000 0x5100000 0x4000000
BSS_SECTIONS := 0x5074000
INPUT_SECTIONS := $(addprefix sections/, $(addsuffix .bin, $(SECTIONS)))
PATCHED_SECTIONS := $(addprefix patched_sections/, $(addsuffix .bin, $(SECTIONS)))

.PHONY: all clean wupserver/wupserver.bin

all: fw.img

$(INPUT):
	@cd bin && python getfwimg.py

gensections:
	@cd sections && python gensections.py

sections/%.bin: $(INPUT) gensections 
	@mkdir -p sections
	@python scripts/anpack.py -in $(INPUT) -e $*,$@

extract: $(INPUT_SECTIONS)

wupserver/wupserver.bin:
	@cd wupserver && make

patched_sections/%.bin: sections/%.bin patches/%.s wupserver/wupserver.bin
	@mkdir -p patched_sections
	@echo patches/$*.s
	@armips patches/$*.s

patch: $(PATCHED_SECTIONS)

fw.img: $(INPUT) $(PATCHED_SECTIONS)
	@python scripts/anpack.py -in $(INPUT) -out fw.img $(foreach s,$(SECTIONS),-r $(s),patched_sections/$(s).bin) $(foreach s,$(BSS_SECTIONS),-b $(s),patched_sections/$(s).bin)

clean:
	@rm -f bin/fw.img bin/fw.img.full.bin
	@rm -f sections/*.bin
	@rm -r patched_sections
	@cd wupserver && make clean
	@rm -f fw.img
