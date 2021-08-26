#! perl -w
######################################
#
# KEEN LITTLE RABBIT EARS is a simple eartraining program.
#
my $version = 0.8;
#
# Written by Matthias Nutt (1999) nutt@forwiss.de_antispam_
# (Please revomve _antispam_ from email address to mail me.)
# 
# http://www.forwiss.de/~msnutt/sound/keenlittleears/ 
######################################

use strict;
use Tk;
use MIDI::Simple;
use English;

######################################
######################################
# VARIABLES
######################################
######################################

######################################
# ADJUST THESE VARIABLES TO YOUR SYSTEM
######################################

# -------------------- BEGIN: THE LINUX AND UNIX SECTION -------------------
# The name of the temporary MIDI file
my $tmp_midi_file = "/tmp/keenlittlerabbitears$$.mid";

# the  keen little rabbit ears configuration file
# Please enter the whole path name
my $configuration_file = "keenlittlerabbitears.cfg";

# The program that should play MIDI files
# Please enter the complete command line!
# Examples
my $play_midi_file_command = "timidity -id $tmp_midi_file ";
#my $play_midi_file_command = "timidity -id $tmp_midi_file > /dev/null";
# ---------------------- END: LINUX AND UNIX --------------------------------

# -------------------- BEGIN: WINDOWS SECTION--------------------------------
if ($OSNAME =~ m/win/i) {

    # puh, we are using windows
    print "\n
	Welcome to KEEN LITTLE RABBIT EARS $version (Windows)
	It is possible that this version does not have all the features
	of the Linux version\n\n
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.\n";

    # ADJUST THE NEXT LINE TO YOUR SYSTEM
    my $patchdir = "C:\\timidity\\patch\\";
    $configuration_file = "C:\\keenlittlerabbitears\\keenlittlerabbitears.cfg";
    $tmp_midi_file = "C:\\keenlittlerabbitears\\ppitch.mid";
    $play_midi_file_command = "C:\\programme\\timidity\\timidity-con.exe -R 10  -L $patchdir $tmp_midi_file";

    print "Keen Little Rabbit Ears $version uses the following command to play MIDI files\n";
    print $play_midi_file_command, "\n";
};
# ----------------------- END WINDOWS SECTION -------------------------------

######################################
# DO NOT CHANGE ANYTHING BELOW
######################################

my $DEBUG = 0;

my $i = 0;               #
my $j = 0;               #
my $element = 0;         #
my $on = 1;              #
my $off = 0;             #  
my $C5  = 60;                     # The tone C5 has the number 60 in MIDI
my $default_root = $C5;           # 
my $random_root = $default_root;  # root of chord, scale or interval, 
                         # can be random if $use_random_root == 1
my $use_random_root = $off;       # flag

my $answer_text_start = "Click \"Next\" to start.";
my $answer_text_next = "Try this one ...";
my $answer_text = $answer_text_start;

# How should the notes be played?
my $scale_like = 0;      # play note after note 
my $chord_like = 1;      # play notes simultaneously
my $play_mode = $scale_like;

my $direction_ascending  =  1;     # play notes in ascending order
my $direction_descending = -1;     # play notes in descending order
my $direction_both       =  0;     # play notes descending of ascending 
my $direction = $direction_ascending; 
my $actual_play_direction = $direction;   

my $use_quiz_mode = $off;

my $tone_list = 0; # Global variable that holds the 
                   # actual played (list of) tones 

my $instrument = 0;    # MIDI Nr. of instrument
my $tempo = 100;       # Tempo 
my $min_tempo = 30;    # minimal tempo
my $max_tempo = 1000;  # maximal tempo

# the type of the tone list
my $intervall_type         = 0; # intervall
my $scale_or_chord_type    = 1; # scale or chord
my $chord_progression_type = 2; # chord progression
 

#####################
# TONES
#####################

my $all_tone_lists = {}; # General Hash 
my $tones = {};          # Hash for pitch testing
my $tone_lists = {};     # List of tones (can be intervall, chord, scale)
my $octave = 12;         # 12 half tones

for ($i = 0; $i < $octave; $i++) {
    $element = %MIDI::number2note->{$i+$C5};
    $element =~ s/s/\#/;
    $tones->{$element}->{"notes"} = [ [ $i ] ] ;
    $tones->{$element}->{"status"} = $on;
    $tones->{$element}->{"sortkey"} = $i;
};

#######################################
# Volume control
#######################################

my $volume_piano       = "p";
my $volume_mezzo_piano = "mp";
my $volume_mezzo       = "mezzo";
my $volume_mezzo_forte = "mf";
my $volume_forte       = "f";
my $volume_fortissimo  = "ff";
my $volume             = $volume_mezzo; # Global var. which holds the volume

#######################################
# TK-Labels, Buttons, etc.
#######################################

my $main_window = 0;

my $drill_window = 0;
my $drill_frame_top = 0;
my $drill_frame_bottom = 0;
my $drill_frame_left = 0;
my $drill_frame_left_frame = 0;
my $drill_frame_right = 0;
my $play_mode_frame = 0;
my $volume_frame = 0;
my $answer_label = 0;
my $warning = 0;
my $next_button = 0;
my $play_it_again_button = 0;

my $select_instrument_window = 0;
my $select_root_tone_window = 0;
my $select_instrument_frame = 0;
my $instrument_listbox_frame = 0;
my $instrument_scrollbar = 0;
my $instrument_listbox = 0;
my $play_direction_frame = 0;

#######################################
# Signals
#######################################
$SIG{INT} = \&catch_signal;  

#######################################
#######################################
## FUNCTIONS
#######################################
#######################################


#######################################
# catch_signal;
#######################################
sub catch_signal {

    my $signal_name = shift;
    if (-f $tmp_midi_file) {
	unlink $tmp_midi_file;
    };
    die "Received signal $signal_name.\n";
};

#######################################
# play_midi_file
#######################################
sub play_midi_file {
  # Play the MIDI file using another external MIDI player
  system("$play_midi_file_command");
}

#######################################
# get_root
#######################################
sub get_root {
  # returns the MIDI number of the deepest tone, that 
  # should be played. This is the root of a chord or scale
  # or the lower note of an interval

  if ($use_random_root) {
    # select random value in the interval 
    # [$default_root - $octave; $default_root + octave]
    my $random_value = int(rand($octave*2) + $C5 - $octave);
    return $random_value;
  } else {
    return $default_root;
  }
}

#######################################
# play_note_after_note
#######################################
sub play_note_after_note {
    my $notelist_ref = shift;
    my $midiobj = MIDI::Simple->new_score();    
    my $opus = 0;
    my $actNote = 0;
    my $actNote2 = 0;
    my $note = 0;
    my @local_note_list = ();

    if ($direction != $direction_both) {
	# use the direction wanted by the user
	$actual_play_direction = $direction;
    }

    ## construct MIDI file
    $midiobj->patch_change(0, $instrument);
    $midiobj->set_tempo(int(60000000 / $tempo));

    foreach $actNote ($actual_play_direction ==  $direction_descending ? 
		      reverse @$notelist_ref:@$notelist_ref) {
	@local_note_list = ();
	foreach $actNote2 (@$actNote) {
	    $note = $actNote2 + $random_root;
	    push @local_note_list, "n$note";
	};
	$midiobj->n("qn", "$volume", @local_note_list);
    };

    # write MIDI file
    $opus = $midiobj->write_score($tmp_midi_file);

    # play MIDI file
    play_midi_file();
    unlink $tmp_midi_file;
};

#######################################
# play_notes_simultaneously
#######################################
sub play_notes_simultaneously {
    my $notelist_ref = shift;
    
    my $midiobj = MIDI::Simple->new_score();    
    my @notes = ("qn", $volume);
    my $list_len = scalar(@$notelist_ref);
    my $opus = 0;
    my $actNote = 0;
    my $actNote2 = 0;
    my $note = 0;

    # construct MIDI file
    $midiobj->patch_change(0, $instrument);
    $midiobj->set_tempo(int(60000000 / $tempo));
    foreach $actNote (@$notelist_ref) {
	foreach $actNote2 (@$actNote) {
	    $note = $actNote2; 
	    $note = $random_root + $note; 
	    push @notes, "n$note";
	};
    };
    $midiobj->n(@notes);

    # write MIDI file
    $opus = $midiobj->write_score($tmp_midi_file);

    ## play MIDI file
    play_midi_file();
    unlink $tmp_midi_file;
};

###############################
# check_answer
###############################
sub check_answer {
    my $answer = shift;
    my $act_lists = shift;
    my $key = 0;
    my $notelist = 0;
        
    # This checks if the "memory addresses" are stringwise equal.
    $notelist = $answer->{"notes"};

    if ($notelist eq $tone_list) {
	if ($answer_text =~ m/RIGHT/) {
	    $answer_text = "GOOD!";
	} else {
	    $answer_text = "RIGHT!";
	}
	$answer_label->configure("-background" => "#3FCA10");
	$next_button->configure(-state => "normal");

	# let the user allow to select
	foreach $key (keys %$act_lists) {
	    $act_lists->{"$key"}->{"checkbutton"}->
		configure(-state => "normal");
	}

	# If quiz-mode is used, immediately play the next test.
	# Dont wait for the next button.
	if ($use_quiz_mode == $on)  {
	    $answer_label->update();   
	    select(undef, undef, undef, 0.25); # sleep for 250 ms
  	    choose_next_tone_list($act_lists);
	}

    } else {
	if ($answer_text =~  m/WRONG/) {
	    $answer_text = "NO, SORRY!";
	} else {
	    $answer_text = "WRONG!";
	}
	$answer_label->configure("-background" => "red");
    }

    $answer_label->update(); 
}

###############################
# choose_next_tone_list 
###############################
sub choose_next_tone_list {
    my $act_lists = shift;
    my $key = 0;
    my @list = ();
    my $random_value;


    $answer_label->configure("-background" => "white");

    # To choose a tone lists (interval, chord, scales)
    # determine only selected ones.
    foreach $key (keys %$act_lists) {
	
	# construct selected things list
	if ($act_lists->{"$key"}->{"status"} == $on) {
	    push @list, $key;
	}
    };
    
    if (scalar(@list) == 0) {
	# user selects nothing
      return if (Exists($warning));
      
      $warning = $main_window->Toplevel(-title => "Warning");
      $warning->Label(-text => 
		    "Warning:\nYou have to select at least one item!\nClick Ok to continue" )->pack();
      $warning->Button(-text => "Ok",
		       -command => sub {destroy $warning}
		       )->pack();
      $warning->waitWindow();
      $warning = 0;
      return;
    }
    
    # forbidd changes to the selection 
    foreach $key (keys %$act_lists) {
	$act_lists->{"$key"}->{"checkbutton"}->
 	    configure(-state => "disabled");
    }

    # Change button state in GUI
    $play_it_again_button->configure(-state => "normal");
    $next_button->configure(-state => "disabled");
      
    # play
    my $value = int (rand(scalar(@list)));
    
    $tone_list = $act_lists->{$list[$value]}->{"notes"};

    $answer_text = $answer_text_next;
    $answer_label->update();    

    # In which direction should the notes be played?
    # This needs to be done here, because the use could
    # use the "play it again" button.
    if ($direction == $direction_both) {
	# randomly select direction
	$random_value = rand(1);
	if ( int($random_value + 0.5) == 0) { 
	    $actual_play_direction = $direction_descending;
	} else {
	    $actual_play_direction = $direction_ascending;
	}
    };
    
    $random_root = get_root();
    play_tone_list(\$tone_list);
}

###############################
# play_tone_list
###############################
sub play_tone_list {
    my $tone_list = shift;
    
    if ($play_mode == $scale_like) {
	play_note_after_note($$tone_list);
    } else {
	play_notes_simultaneously($$tone_list);
    }
}

################################
# play 440 Hz
################################
sub play_440Hz {
    
    play_tone_list( \[  [ $C5 + 9 - $random_root] ] );
}

################################
# change_button_state
################################
sub change_button_state {
  my $act_element = shift;

  if ($act_element->{"status"} == $off) {
    $act_element->{"button"}->configure(-state => "disabled");
  } else {
    $act_element->{"button"}->configure(-state => "normal");
  }
}

#######################################
# select_instrument
#######################################
sub select_instrument {

  # Window already opened?
  return if (Exists($select_instrument_window));
  
  $select_instrument_window = 
    $main_window->Toplevel(-title => "Select instrument");
  
  $instrument_listbox_frame = $select_instrument_window->Frame();
  $instrument_listbox_frame->pack();

  $instrument_listbox = 
    $instrument_listbox_frame->Listbox(-height => "10",
				      -selectmode => "single");
  
  # insert elements
  my @all_instruments = ("end");
  foreach $instrument (sort {$a <=> $b } keys %MIDI::number2patch) {
    $instrument = %MIDI::number2patch->{$instrument};
    push @all_instruments, $instrument;
  };
  
  $instrument_listbox->insert(@all_instruments);
  
  # scrollbar
  $instrument_scrollbar = 
    $instrument_listbox_frame->
      Scrollbar(-command => ["yview", $instrument_listbox]);

  $instrument_listbox->configure(-yscrollcommand => 
				 ["set", $instrument_scrollbar]);

  # Pack
  $instrument_listbox->pack(-side => "left", -fill => "both", -expand => 1);
  $instrument_scrollbar->pack(-side => "right", -fill => "y");
  
  # Highlight actually used instrument
  if ($instrument > 2) {
      $instrument_listbox->see($instrument-2);
  } else {
      $instrument_listbox->see($instrument);
  };
  $instrument_listbox->selectionSet($instrument);


  $select_instrument_window->
    Button(-text => "OK",
	   -command => 
	   sub { 
	       if (defined $instrument_listbox->curselection()) {
		   $instrument = $instrument_listbox->curselection();
	       } 
	       destroy $select_instrument_window;
	       $select_instrument_window = 0;
	   })->pack();
};

#######################################
# select_root_tone
#######################################
sub select_root_tone {

    my @all_notes; 
    my $first_entry;
    my $last_entry;
    my $selected_value;
    my $deepest_note;
    my $highest_note;
    my $random_entry;


    # Window already opened?
    return if (Exists($select_root_tone_window));
    
    $select_root_tone_window = 
	$main_window->Toplevel(-title => "Select root");
    
    my $root_tone_listbox_frame = $select_root_tone_window->Frame();
    $root_tone_listbox_frame->pack();
    
    my $root_tone_listbox = 
	$root_tone_listbox_frame->Listbox(-height => "10",
					  -selectmode => "single");
    
    # insert elements
    $deepest_note = $C5 - $octave;
    $highest_note = $C5 + $octave + 1;
    $random_entry = $highest_note;
    for ($i = $deepest_note;
	 $i < $highest_note; 
	 $i++) {
	$element = %MIDI::number2note->{$i};
	$element =~ s/s/\#/;
	$root_tone_listbox->insert("end", $element);
    };
    $root_tone_listbox->insert("end", "RANDOM");

    # scrollbar
    my $root_tone_scrollbar = 
	$root_tone_listbox_frame->
	    Scrollbar(-command => ["yview", $root_tone_listbox]);
    
    $root_tone_listbox->configure(-yscrollcommand => 
				  ["set", $root_tone_scrollbar]);
    
    # Pack
    $root_tone_listbox->pack(-side => "left", -fill => "both", -expand => 1);
    $root_tone_scrollbar->pack(-side => "right", -fill => "y");

    # Highlight actually root
    if ($use_random_root != $on) {
	$root_tone_listbox->see($default_root - $deepest_note-2);
	$root_tone_listbox->selectionSet($default_root - $deepest_note);
    } else {
	$root_tone_listbox->see($random_entry-$deepest_note);
	$root_tone_listbox->selectionSet($random_entry-$deepest_note);
    }

    # OK button
    $select_root_tone_window->
	Button(-text => "OK",
	       -command => 
	       sub { 
		   if (defined $root_tone_listbox->curselection()) {
		       $selected_value = $root_tone_listbox->curselection();
		       if ($selected_value  == 
			   ($random_entry - $deepest_note)) {
			   $use_random_root = $on;
		       } else {
			   $default_root = 
			       $selected_value + $deepest_note;
			   $use_random_root = $off;
		       }
		   } 
		   destroy $select_root_tone_window;
		   $select_root_tone_window = 0;
	       })->pack();
};

#######################################
# exercise 
#######################################
sub exercise {
  # Open the drill window and generate all those buttons
  # and bind them to the correct functions
  
  my $act_chords = shift;
  my $tmp_string = "";
  my $act_button  = 0;
  my $act_checkbutton  = 0;
  my $act_tone_list_type = 0;

  ###########################
  # Build window for exercise
  ###########################

  # Does the window already exist?
  if (Exists($drill_window)) {
      return; 
  } else {
      $drill_window = 
	  $main_window->
	      Toplevel(-title => "Keen Little Rabbit Ears Drill Window");
  };
  $drill_frame_top = $drill_window->Frame();
  $drill_frame_top->pack(-side=> "top", 
			 -fill => "both", 
			 -expand => "yes");
  $drill_frame_bottom = $drill_window->Frame();
  $drill_frame_bottom->pack(-side => "bottom", 
				  -fill => "both", 
			    -expand => "yes");
  $drill_frame_left = $drill_window->Frame();
  $drill_frame_left->pack(-side => "top",
			  -fill => "both", 
			  -expand => "yes");
    
  # Notes (Intervals, chords or scales)
  $i = 0;
  $element = 0; 
  
  foreach $element (sort {$act_chords->{$a}->{"sortkey"} <=> 
			      $act_chords->{$b}->{"sortkey"}}
		    keys %$act_chords) {

    # i is the memory address of the list with notes
    $i = $act_chords->{$element}->{"notes"}; 
    $i = $act_chords->{$element};
    # Frame 
    $drill_frame_left_frame = $drill_frame_left->Frame();
    $drill_frame_left_frame->pack(-side => "top",
				  -fill => "both", 
				  -expand => "yes");

    # declare Button and Checkbox to get the memory addresses
    $act_button = $drill_frame_left_frame->Button();
    $act_checkbutton = $drill_frame_left_frame->Checkbutton();

    $act_chords->{$element}->{"button"} = $act_button;
    $act_chords->{$element}->{"checkbutton"} = $act_checkbutton;

    # use declared Checkbox
    $act_checkbutton->
	configure(-variable => \$act_chords->{$element}->{"status"},
		  -onvalue =>  $on,
		  -offvalue => $off,
		  -command =>  [ \&change_button_state , 
                                 $act_chords->{$element} ]
		  );
    $act_checkbutton->pack(-side => "left");
    
    # use declared Button
    $act_button->configure(-text => "$element",
			   -command => [ \&check_answer, 
					 $i,
					 $act_chords ]
			  );
    $main_window->bind($act_button, 
		       "<3>", 
		       sub { play_tone_list 
				 (\$act_chords->{$element}->{"notes"}) });

    $act_button->pack(-side => "right", -fill => "both", -expand => "yes");
    if ($act_chords->{$element}->{"status"} == $off) {
	$act_button->configure(-state => "disabled");
    };
    $act_tone_list_type = $act_chords->{$element}->{"tone_list_type"};

  }
  # Label and Buttons on Bottom
  add_labels_and_buttons_on_bottom($act_chords, $act_tone_list_type);
};

##################################
# add_label_and_button_on_bottom
##################################
sub add_labels_and_buttons_on_bottom {
  # Draw the buttons in the bottom of the drill window 
 
  my $act_chords = shift;
  my $act_tone_list_type = shift;
  my $control_button_frame = 0;
  my $select_button_frame = 0;
  
  # Label and Buttons on Bottom
  $answer_text = $answer_text_start;
  $answer_label = $drill_frame_bottom->
    Label(-textvariable => \$answer_text,
	  -bg => "white");
  $answer_label->pack(-fill => "both", -expand => "yes");

  $control_button_frame  = $drill_frame_bottom->
      Frame()->pack(-expand => "both", -fill => "both");
  
  $next_button = $control_button_frame ->
    Button(-text => "Next",
 	   -command => [ \&choose_next_tone_list, $act_chords ]
	  );
  $next_button->pack(-fill => "both", -expand => "yes",
		     -side => "left");

  $play_it_again_button = $control_button_frame->
    Button(-text    => "Play it again",
	   -command => [ \&play_tone_list, \$tone_list ],
	   -state   => "disabled" 
	  );
  $play_it_again_button->pack(-fill => "both", 
			      -expand => "no");

  $control_button_frame->
    Button(-text => "Stop exercise",
	   # -command => [ \& stop_drill_exercise ]
	   -command => sub { destroy $drill_window }
	  )->pack(-fill => "both", -expand => "no",
		  -side => "right");
  
  $select_button_frame  = $drill_frame_bottom->
      Frame()->pack(-expand => "both", -fill => "both");

  $select_button_frame->
    Button(-text => "Select instrument",
	   -command => [ \&select_instrument ]
	   )->pack(-fill => "both", -expand => "yes",
		   -side => "left");

  if ($act_chords != $tones) {
      $select_button_frame->
	  Button(-text => "Select root",
		 -command => [ \&select_root_tone ]
		 )->pack(-fill => "both", -expand => "yes",
			 -side => "left");
  };
  $select_button_frame->
    Button(-text => "440Hz",
	   -command => [ \&play_440Hz ]
	   )->pack(-fill => "both", -expand => "yes",
		   -side => "left");


  $volume_frame = $drill_frame_bottom->Frame();
  $volume_frame->pack();
  $volume_frame->
    Label(-text => "Volume :"
	 )->pack(-side => "left", -fill => "both", expand => "yes");
  $volume_frame->
    Radiobutton(-variable => \$volume, 
		-value => $volume_piano,
		-text => "p"
	       )->pack(-side => "left", -fill => "both", expand => "yes");
  $volume_frame->
    Radiobutton(-variable => \$volume, 
		-value => $volume_mezzo_piano,
		-text => "mp"
	       )->pack(-side => "left", -fill => "both", expand => "yes");
  $volume_frame->
    Radiobutton(-variable => \$volume, 
		-value => $volume_mezzo,
		-text => "mezzo"
	       )->pack(-side => "left", -fill => "both", expand => "yes");
  $volume_frame->
    Radiobutton(-variable => \$volume, 
		-value => $volume_mezzo_forte,
		-text => "mf"
	       )->pack(-side => "left", -fill => "both", expand => "yes");
  $volume_frame->
    Radiobutton(-variable => \$volume, 
		-value => $volume_forte,
		-text => "f"
	       )->pack(-side => "left", -fill => "both", expand => "yes");
  $volume_frame->
    Radiobutton(-variable => \$volume, 
		-value => $volume_fortissimo,
		-text => "ff"
	       )->pack(-side => "left", -fill => "both", expand => "yes");


  if (($act_chords != $tones) &&
      ($act_tone_list_type != $chord_progression_type)) {
      $play_mode_frame = $drill_frame_bottom->Frame();
      $play_mode_frame->pack();
      $play_mode_frame->
	  Label(-text => "Play it :"
		)->pack(-side => "left", 
			-fill => "both", 
			-expand => "yes");
      $play_mode_frame->
	  Radiobutton(-variable => \$play_mode, 
		      -value => $scale_like,
		      -text => "scale like"
		      )->pack(-side => "left", 
			      -fill => "both", 
			      -expand => "yes");
      $play_mode_frame->
	  Radiobutton(-variable => \$play_mode, 
		      -value => $chord_like,
		      -text => "chord like"
	       )->pack(-side => "right", 
		       -fill => "both", 
		       -expand => "yes");
      
      $play_direction_frame = $drill_frame_bottom->Frame();
      $play_direction_frame->pack();
       $play_direction_frame->
         Label(-text => "Direction :"
               )->pack(-side => "left", 
                       -fill => "both", 
                       -expand => "yes");
       $play_direction_frame->
         Radiobutton(-variable => \$direction, 
                     -value => $direction_ascending,
                     -text => "ascending"
                     )->pack(-side => "left", 
                             -fill => "both", 
                             -expand => "yes");

       $play_direction_frame->
         Radiobutton(-variable => \$direction, 
                     -value => $direction_descending,
                     -text => "descending"
                     )->pack(-side => "left", 
                             -fill => "both", 
                             -expand => "yes");

       $play_direction_frame->
         Radiobutton(-variable => \$direction, 
                     -value => $direction_both,
                     -text => "both"
                     )->pack(-side => "left", 
                             -fill => "both", 
                             -expand => "yes");

  } else {
      $direction = $direction_ascending;
      if ($act_chords == $tones){

	  # no random root during pitch drill
	  $use_random_root = $off;
	  $default_root = $C5;
	  $random_root  =  get_root();
      };  
  };

  $drill_frame_bottom->
      Checkbutton(-text => "Quiz mode",
		  -variable => \$use_quiz_mode,
		  -offvalue => $off,
		  -onvalue  => $on
		  )->pack(-side => "left");
  
  $drill_frame_bottom->
      Scale(-label => "Tempo",
	    -variable => \$tempo,
	    -from => $min_tempo,
	    -to  => $max_tempo,
	    -showvalue => 0,
	    -orient => "horizontal",
	    )->pack(-side => "right", -fill => "both", -expand => "yes");



};


#######################################
# read_configuration_file
#######################################
sub read_configuration_file {
    my $filename = shift;
    my $line = "";
    my @line = ();
    my @tmp_list = ();
    my @tones = ();
    my $tone = 0;
    my $new_tones_list = 0;
    my $identifier = "";
    my $tmp_value = "";
    my $name = "";
    my $status = $off;
    my $identifier_counter = 0;
    my $name_counter = 0;
    my $seen_keys = {};
    my $new_hash = 0;
    my $true = 1;
    my $false = 0;
    my $reading_a_chord = $false;
    my $new_chord = 0;
    my $act_tone_list_type = 0;
    my $tone_list_length = 0;

    # open configuration file
    open(IN, $filename) ||
	die "Keen Little Rabbit Ears $version can not open $configuration_file.\n";

    while (defined($line = <IN>)) {
	
	if ($line =~ m/^\#/) {
	    next; # skip comments
	};
	
	if (! ($line =~ m/[A-Za-z]/)) {
	    next; # skip empty lines
	    
	}

	# Extract identifier, name, status and tones
	@line = split(";", $line);

	if (scalar(@line) < 3) {
	    die ("Error in configuration file $configuration_file",
		 " in line $line\n");
	}
	
	# Extract Identifier and name

	$tmp_value = $line[0];
	$identifier = $line[0];
	$identifier =~ s/:.*//;

	$name = $line[0];
	$name =~ s/^(.*?)://;
	chomp($name);

	# Extract status
	$line[1] =~ s/^ +//;
	($tmp_value, $status) = split(" ", $line[1]);
	if (not ($tmp_value =~ m/status/i)) {
	    die ("Error in configuration file $configuration_file",
		 " in line $line\nSomething is wrong with the status tag\n");
	};
	if ($status =~ m/on/i) {
	    $status = $on;
	} else {
	    if ($status =~ m/off/i) {
		$status = $off;
	    } else {
		die ("Error in configuration file $configuration_file",
		     " in line $line\nSomething is wrong with ",
		     "the status value\n");
	    }
	}
	
	# Extract tones / notes
	# 1. correct whitespace in list of tones
	$line[2] =~ s/\[/ \[ /g;
	$line[2] =~ s/\]/ \]  /g;
	#$line[2] =~ s/,/ ,  /g;
	$line[2] =~ s/,/ /g;
	$line[2] =~ s/^ +//;

	($tmp_value, @tones) = split(" ", $line[2]); 
	if (not ($tmp_value =~ m/tones/i)) {
	    die ("Error in configuration file $configuration_file",
		 " in line $line\nSomething is wrong with the tone list");
	}

	# A tone list will be a list of lists, 
	# This means a list of a list of tones 
	# in a later version this will be a hash,
	# which allows to easily add other things
	# like duration, note_length or instrument information.
	$new_tones_list = [];

	foreach $tone (@tones) {
	    if (!(($tone =~ m/\[/) ||
		  ($tone =~ m/\]/) )) {
		if ($reading_a_chord == $false)  { 
		    # no chord, just a simple tone
		    # -> add it to the list
		    $tone =~ s/,.*//;
		    
		    push @$new_tones_list, [ $tone ] ;
		} else {
		    # another tone of a chord
		    # save it to a list and add the complete list later
		    push @$new_chord, $tone;
		}
	    } else {
		if ($tone =~ m/\[/) { # Start chord reading 
		    $reading_a_chord = $true;
		    $new_chord = [];
		    next;
		} else {
		    if ($tone =~ m/\]/) {
			# all tones of the chords are reed,
			# so add it to the list
			
			push @$new_tones_list, $new_chord;
			$reading_a_chord = $false;
		    };
		};
	    };
	};

	# What kind of tonelist is it?
	# an intervall, a chord, a scale or a chord progression?
	if ($line[2] =~ m/\[/) {
	    $act_tone_list_type = $chord_progression_type;
	} else {
	    $tone_list_length = scalar (@$new_tones_list);
	    if ($tone_list_length == 2) {
		$act_tone_list_type = $intervall_type;
	    } else {
		$act_tone_list_type = $scale_or_chord_type;
	    }
	};

	# Enter the identifier into the global Hash
	if (not exists %$all_tone_lists->{$identifier}) {
	    # New entry
	    $all_tone_lists->{$identifier} = {};
            $all_tone_lists->{$identifier}->{"sortkey"} = 
		$identifier_counter++;
            $all_tone_lists->{$identifier}->{"tonelists"} = {};
	};

	# Enter the name  into the identifier hash
	if (not exists %{$all_tone_lists->{$identifier}->
	    {"tonelists"}}->{$name}) {
	    # new entry
	    $all_tone_lists->{$identifier}->{"tonelists"}->{$name} = {};
	};


  	$new_hash = {
  		     "button" => 0,
  		     "checkbutton" => 0,
  		     "notes" => $new_tones_list,
  		     "name"  => $name,
  		     "status" => $status,
  		     "sortkey" => $name_counter++,
		     "tone_list_type" => $act_tone_list_type
  		     };

  	$all_tone_lists->{$identifier}->{"tonelists"}->{$name} = $new_hash;
    };
};

#######################################
#######################################
## MAIN
#######################################
#######################################

srand();

# Check for arguments
if (scalar(@ARGV) == 0) {
    read_configuration_file($configuration_file);
} else {
    read_configuration_file($ARGV[0]);
}

$main_window = new MainWindow(-title => "Keen Little Rabbit Ears $version");
$main_window->Label(-text => 
   "Welcome to KEEN LITTLE RABBIT EARS, the easy to use ear training program.

This program is free software under GPL.
The configuration file contains definitions of all intervals, chords, scales or 
chord progressions listed below. It can be edited easily to include more 
features. See the README file for details.

(c) Matthias Nutt, 1999"
    )->pack(-expand => "yes", -fill => "x");


# One button for each identifier from the config file
foreach $element (sort { $all_tone_lists->{$a}->{"sortkey"} <=>
			     $all_tone_lists->{$b}->{"sortkey"} 
		     } keys %$all_tone_lists) {
    
    $main_window->Button(-text => "$element",
  			 -command => [ \&exercise, 
  				       $all_tone_lists->{$element}->
				       {"tonelists"} ]
  			 )->pack(-expand => "yes", -fill => "both");
};

$main_window->Button(-text => "Pitch",
                     -command => [ \&exercise, $tones ]
                    )->pack(-expand => "yes", -fill => "both");

$main_window->Button(-text => "Exit",
                     -command => sub{
			 if (-f $tmp_midi_file) {
			     unlink $tmp_midi_file;
			 }; 
			 destroy $main_window
			 }
                    )->pack(-expand => "yes", -fill => "both");

############### 
#  Main loop
###############
MainLoop; 
