#
#   $Id: GNUmakefile 3455 2009-04-06 22:50:20Z leighsmith $
#   Defined In: Calliope
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Leigh M. Smith
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# Install into the local root by default
# GNUSTEP_INSTALLATION_DOMAIN = LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Calliope

APPICON = Images/CallAppIcon.tiff
ADDITIONAL_LIB_DIRS =

PACKAGE_NAME=Calliope

# This is now the ONLY lib you have to include when compiling
# a SndKit program. If you want to compile a MusicKit program,
# use -lMusicKit instead. It doesn't matter if you do both.

ADDITIONAL_TOOL_LIBS += -lMusicKit

ADDITIONAL_CFLAGS += -g

# This may not be necessary anymore.
ifeq (mingw32, $(GNUSTEP_HOST_OS))
  CYG_DRIVE = $(shell cygpath -w '/' | tr '\\' '/' )
  ADDITIONAL_LIB_DIRS = -L$(CYG_DRIVE)/usr/local/lib
  ADDITIONAL_FLAGS += -I$(CYG_DRIVE)/usr/local/include
endif

ADDITIONAL_FLAGS += -g
ADDITIONAL_LDFLAGS += -g

# The Objective-C source files to be compiled

SUPPORT_SOURCES = Calliope_main.m \
                  DrawingFunctions.m \
                  draw.m \
                  muxchar.m \
                  muxCollide.m \
                  muxlow.m

CLASSES = AccentInspector.m \
          Accent.m \
          AppDefaults.m \
          BarInspector.m \
          Barline.m \
          BeamInspector.m \
          Beam.m \
          BlockInspector.m \
          Block.m \
          Bracket.m \
          BrackInspector.m \
          CallInst.m \
          CalliopeAppController.m \
          CalliopeWindow.m \
          CallPageLayout.m \
          CallPart.m \
          CastInspector.m \
          Channel.m \
          ChordGroup.m \
          ClefInspector.m \
          Clef.m \
          Course.m \
          DragMatrix.m \
          EnclosureInspector.m \
          Enclosure.m \
          FileCompatibility.m \
          FlippedView.m \
          GNChord.m \
          GNote.m \
          Graphic.m \
          GraphicView.m \
          GVCommands.m \
          GVFormat.m \
          GVGlobal.m \
          GVMenu.m \
          GVPasteboard.m \
          GVPerform.m \
          GVSelection.m \
          Hanger.m \
          ImageGraphic.m \
          KeyboardFilter.m \
          KeyInspector.m \
          KeySig.m \
          LayBarInspector.m \
          LigatureInspector.m \
          Ligature.m \
          MarginInspector.m \
          Margin.m \
          MetroInspector.m \
          Metro.m \
          MultiView.m \
          MyNSMutableAttributedString.m \
          NeumeInspector.m \
          Neume.m \
          NeumeNew.m \
          NewPanel.m \
          NoteGroupInspector.m \
          NoteGroup.m \
          NoteHead.m \
          NoteInspector.m \
          OAPLAExtensions.m \
          OpusDocument.m \
          Page.m \
          PageScrollView.m \
          PlayInspector.m \
          PrefBlock.m \
          Preferences.m \
          ProgressDisplay.m \
          RangeInspector.m \
          Range.m \
          RestInspector.m \
          Rest.m \
          RunInspector.m \
          Runner.m \
          SquareNoteInspector.m \
          SquareNote.m \
          Staff.m \
          StaffObj.m \
          StaffTrans.m \
          SysAdjust.m \
          SysCommands.m \
          SysInspector.m \
          System.m \
          TabInspector.m \
          Tablature.m \
          TabTuner.m \
          TextGraphic.m \
          TextInspector.m \
          TextVarCell.m \
          TieInspector.m \
          Tie.m \
          TieNew.m \
          TimedObj.m \
          TimeInspector.m \
          TimeSig.m \
          ToneTool.m \
          TuningView.m \
          TupleInspector.m \
          Tuple.m \
          UserInstrument.m \
          Verse.m \
          VoiceInspector.m \
          Volta.m

$(APP_NAME)_OBJC_FILES = $(CLASSES) $(SUPPORT_SOURCES)

SRCS = $(TEST_APP_NAME:=.m)

HDRS =

DIST_FILES = $(SRCS) $(HDRS)

$(APP_NAME)_MAIN_MODEL_FILE = Calliope
$(APP_NAME)_RESOURCE_FILES = English.lproj


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
