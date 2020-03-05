#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

TOOLDIR := $(DEVKITPRO)/tools/bin

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
#---------------------------------------------------------------------------------

TARGET			:=	Quake2CTR
BUILD			:=	build
SOURCES			:=	.
APP_AUTHOR		:=	MasterFeizz
DATA			:=	ctr/assets/
INCLUDES		:=	.
RESOURCES		:=	assets

GAME			=	$(MAKECMDGOALS)
ifeq ($(GAME),)
	GAME		=	CTR
else
	GAME		=	`echo $@ | tr a-z A-Z`
endif

#---------------------------------------------------------------------------------
# Resource Setup
#---------------------------------------------------------------------------------
include $(TOPDIR)/$(RESOURCES)/game.info

ifeq ($(GAME),)
	BANNER_AUDIO	:= $(RESOURCES)/ctr_audio
	BANNER_IMAGE	:= $(RESOURCES)/ctr_banner
	ICON			:= $(RESOURCES)/ctr_icon.png
else
	BANNER_AUDIO	:= $(RESOURCES)/ctr_audio
	BANNER_IMAGE	:= $(RESOURCES)/$(GAME)_banner
	ICON			:= $(RESOURCES)/$(GAME)_icon.png
endif

RSF					:= $(TOPDIR)/$(RESOURCES)/template.rsf

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard

CFLAGS	:=	-g -Wall -O3 -mword-relocations -ffast-math \
			-fomit-frame-pointer -ffunction-sections \
			$(ARCH)

CFLAGS	+=	$(INCLUDE) -DARM11 -D_3DS -DREF_HARD_LINKED -DGAME_HARD_LINKED

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS	:=	-g $(ARCH)
LDFLAGS	=	-specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS	:= -lctru -lm

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(CTRULIB)


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

SYSTEM = 	ctr/cd_ctr.o \
			ctr/vid_ctr.o \
			ctr/snddma_ctr.o \
			ctr/sys_ctr.o \
			ctr/in_ctr.o \
			ctr/net_ctr.o \
			ctr/swimp_ctr.o \
			ctr/heap_ctr.o \
			ctr/touch_ctr.o \
			ctr/glob.o

CLIENT =	client/cl_input.o \
			client/cl_inv.o \
			client/cl_main.o \
			client/cl_cin.o \
			client/cl_ents.o \
			client/cl_fx.o \
			client/cl_parse.o \
			client/cl_pred.o \
			client/cl_scrn.o \
			client/cl_tent.o \
			client/cl_view.o \
			client/menu.o \
			client/console.o \
			client/keys.o \
			client/snd_dma.o \
			client/snd_mem.o \
			client/snd_mix.o \
			client/qmenu.o \
			client/cl_newfx.o 

QCOMMON = 	qcommon/cmd.o \
			qcommon/cmodel.o \
			qcommon/common.o \
			qcommon/crc.o \
			qcommon/cvar.o \
			qcommon/files.o \
			qcommon/md4.o \
			qcommon/net_chan.o \
			qcommon/pmove.o 

SERVER = 	server/sv_ccmds.o \
			server/sv_ents.o \
			server/sv_game.o \
			server/sv_init.o \
			server/sv_main.o \
			server/sv_send.o \
			server/sv_user.o \
			server/sv_world.o

REFSOFT = 	ref_soft/r_alias.o \
			ref_soft/r_main.o \
			ref_soft/r_light.o \
			ref_soft/r_misc.o \
			ref_soft/r_model.o \
			ref_soft/r_part.o \
			ref_soft/r_poly.o \
			ref_soft/r_polyse.o \
			ref_soft/r_rast.o \
			ref_soft/r_scan.o \
			ref_soft/r_sprite.o \
			ref_soft/r_surf.o \
			ref_soft/r_aclip.o \
			ref_soft/r_bsp.o \
			ref_soft/r_draw.o \
			ref_soft/r_edge.o \
			ref_soft/r_image.o


CFILES		:=	$(CLIENT) $(QCOMMON) $(SERVER) $(GAME_FILES) $(REFSOFT) $(SYSTEM)
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:=	$(addsuffix .o,$(BINFILES)) \
			$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

#---------------------------------------------------------------------------------
# Inclusion of romfs folder and building SMDH
#---------------------------------------------------------------------------------
ifneq ($(ROMFS),)
	export _3DSXFLAGS += --romfs=$(TOPDIR)/$(ROMFS)
endif

#export _3DSXFLAGS += --smdh=$(OUTPUT).smdh

.PHONY: $(GAME) clean all
#---------------------------------------------------------------------------------

%:
	@$(MAKE) --no-print-directory -f $(CURDIR)/Makefile GAME=$(GAME)

$(GAME):
	@$(MAKE) clean
	@mkdir -p build/client build/qcommon build/server build/ref_soft build/ctr $(GAME_FOLDERS)
	@echo "building2 $(TARGET)... $@ - $(GAME_FOLDERS)"
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile GAME=$(GAME)

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) *.3dsx *.smdh *.elf *.cia


#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

APP_TITLE         := $(shell echo "$(APP_TITLE)" | cut -c1-128)
APP_DESCRIPTION   := $(shell echo "$(APP_DESCRIPTION)" | cut -c1-256)
APP_AUTHOR        := $(shell echo "$(APP_AUTHOR)" | cut -c1-128)
APP_PRODUCT_CODE  := $(shell echo $(APP_PRODUCT_CODE) | cut -c1-16)
APP_UNIQUE_ID     := $(shell echo $(APP_UNIQUE_ID) | cut -c1-7)
APP_VERSION_MAJOR := $(shell echo $(APP_VERSION_MAJOR) | cut -c1-3)
APP_VERSION_MINOR := $(shell echo $(APP_VERSION_MINOR) | cut -c1-3)
APP_VERSION_MICRO := $(shell echo $(APP_VERSION_MICRO) | cut -c1-3)

ifneq ("$(wildcard $(TOPDIR)/$(BANNER_IMAGE).cgfx)","")
	BANNER_IMAGE_FILE := $(TOPDIR)/$(BANNER_IMAGE).cgfx
	BANNER_IMAGE_ARG  := -ci $(BANNER_IMAGE_FILE)
else
	BANNER_IMAGE_FILE := $(TOPDIR)/$(BANNER_IMAGE).png
	BANNER_IMAGE_ARG  := -i $(BANNER_IMAGE_FILE)
endif

ifneq ("$(wildcard $(TOPDIR)/$(BANNER_AUDIO).cwav)","")
	BANNER_AUDIO_FILE := $(TOPDIR)/$(BANNER_AUDIO).cwav
	BANNER_AUDIO_ARG  := -ca $(BANNER_AUDIO_FILE)
else
	BANNER_AUDIO_FILE := $(TOPDIR)/$(BANNER_AUDIO).wav
	BANNER_AUDIO_ARG  := -a $(BANNER_AUDIO_FILE)
endif

APP_ICON := $(TOPDIR)/$(ICON)

COMMON_MAKEROM_PARAMS := -rsf $(RSF) -target t -exefslogo -elf $(OUTPUT).elf -icon icon.icn \
-banner banner.bnr -DAPP_TITLE="$(APP_TITLE)" -DAPP_PRODUCT_CODE="$(APP_PRODUCT_CODE)" \
-DAPP_UNIQUE_ID="$(APP_UNIQUE_ID)" -DAPP_SYSTEM_MODE="64MB" -DAPP_SYSTEM_MODE_EXT="Legacy" \
-major "$(APP_VERSION_MAJOR)" -minor "$(APP_VERSION_MINOR)" -micro "$(APP_VERSION_MICRO)"

ifneq ($(ROMFS),)
	APP_ROMFS := $(TOPDIR)/$(ROMFS)
	COMMON_MAKEROM_PARAMS += -DAPP_ROMFS="$(APP_ROMFS)"
endif

ifeq ($(OS),Windows_NT)
	MAKEROM = makerom.exe
	BANNERTOOL = bannertool.exe
else
	MAKEROM = $(TOOLDIR)/makerom
	BANNERTOOL = $(TOOLDIR)/bannertool
endif

ifneq ($(MOD_FLAGS),)
	CFLAGS	+=	$(MOD_FLAGS)
endif

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
all : $(OUTPUT).elf $(OUTPUT).smdh $(OUTPUT).3dsx $(OUTPUT).cia

$(OUTPUT).elf	:	$(OFILES)

$(OUTPUT).3dsx	:	$(OUTPUT).elf $(OUTPUT).smdh

$(OUTPUT).cia	:	$(OUTPUT).elf banner.bnr icon.icn
	@$(MAKEROM) -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false $(COMMON_MAKEROM_PARAMS)
	@echo "built ... $(TARGET).cia"

banner.bnr : $(BANNER_IMAGE_FILE) $(BANNER_AUDIO_FILE)
	@$(BANNERTOOL) makebanner $(BANNER_IMAGE_ARG) $(BANNER_AUDIO_ARG) -o banner.bnr > /dev/null

icon.icn : $(TOPDIR)/$(ICON)
	@$(BANNERTOOL) makesmdh -s "$(APP_TITLE)" -l "$(APP_TITLE)" -p "$(APP_AUTHOR)" -i $(TOPDIR)/$(ICON) -o icon.icn > /dev/null

cia : $(OUTPUT).cia

#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

# WARNING: This is not the right way to do this! TODO: Do it right!
#---------------------------------------------------------------------------------
%.vsh.o	:	%.vsh
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@python $(AEMSTRO)/aemstro_as.py $< ../$(notdir $<).shbin
	@bin2s ../$(notdir $<).shbin | $(PREFIX)as -o $@
	@echo "extern const u8" `(echo $(notdir $<).shbin | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"_end[];" > `(echo $(notdir $<).shbin | tr . _)`.h
	@echo "extern const u8" `(echo $(notdir $<).shbin | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> `(echo $(notdir $<).shbin | tr . _)`.h
	@echo "extern const u32" `(echo $(notdir $<).shbin | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> `(echo $(notdir $<).shbin | tr . _)`.h
	@rm ../$(notdir $<).shbin

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
