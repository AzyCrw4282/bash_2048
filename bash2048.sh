#!/usr/bin/env bash


# help -> https://github.com/AzyCrw4282/awesome-cheatsheets/blob/master/languages/bash.sh
	
#important variables
declare -ia board    # an integer array that keeps track of game status of type integers
#-i var defines of type integer
declare -i pieces    # number of pieces present on board
declare -i score=0   # score variable
declare -i flag_skip # flag that prevents doing more than one operation on
                     # single field in one step
declare -i moves     # stores number of possible moves to determine if player lost 
#String variable type                     # the gam
declare ESC=$'\e'    # escape byte
declare header="Bash 2048 v1.1 (Azky's Game)"

declare -i start_time=$(date +%s)

#default config
declare -i board_size=4
declare -i target=2048
declare -i reload_flag=0
declare config_dir="$HOME/.bash2048"

#for colorizing numbers. An array is used of even numbers to store the value of colours.
declare -a colors
colors[2]=33         # yellow text
colors[4]=32         # green text
colors[8]=34         # blue text
colors[16]=36        # cyan text
colors[32]=35        # purple text
colors[64]="33m\033[7"        # yellow background
colors[128]="32m\033[7"       # green background
colors[256]="34m\033[7"       # blue background
colors[512]="36m\033[7"       # cyan background
colors[1024]="35m\033[7"      # purple background
colors[2048]="31m\033[7"      # red background (won with default target)

#This ensures that all information written to it are discarded
exec 3>/dev/null     # no logging by default

trap "end_game 0 1" INT #handle INT signal

#close of methods, statements with their reversed name, i.e. case -> esac and if to fi3

#simplified replacement of seq command
function _seq {
	#lcoal variables
  local cur=1
  local max
  local inc=1
  case $# in 
    1) let max=$1;;
    2) let cur=$1
       let max=$2;;
    3) let cur=$1
       let inc=$2
       let max=$3;;
  esac
  #Use of $man and $cur variables
  while test $max -ge $cur; do #tests if one variables is greater than the other
    printf "$cur "
    let cur+=inc
  done
}
"""
Each open file gets assigned a file descriptor. 
The file descriptors for stdin, stdout, and stderr are 0, 1, and 2, respectively. 
For opening additional files, there remain descriptors 3 to 9. 
It is sometimes useful to assign one of these additional file descriptors to stdin, stdout, 
or stderr as a temporary duplicate link. This simplifies restoration to normal after complex redirection
and reshuffling

"""
# 
# prints currect status of the game, last added pieces are marked red
#shell colours are used to print the elements. Works by nest for loop iteration to change colour.
function print_board {
  clear
  printf "$header pieces=$pieces target=$target score=$score\n"
  printf "Board status:\n" >&3
  printf "\n"
  printf '/------'
  for l in $(_seq 1 $index_max); do #prints the board one by one using the seq function
    printf '+------'
  done
  printf '\\\n'
  for l in $(_seq 0 $index_max); do
    printf '|'
    for m in $(_seq 0 $index_max); do
      if let ${board[l*$board_size+m]}; then
        if let '(last_added==(l*board_size+m))|(first_round==(l*board_size+m))'; then
          printf '\033[1m\033[31m %4d \033[0m|' ${board[l*$board_size+m]} #Specifies a shell colour for the element
        else
          printf "\033[1m\033[${colors[${board[l*$board_size+m]}]}m %4d\033[0m |" ${board[l*$board_size+m]}
        fi
        printf " %4d |" ${board[l*$board_size+m]} >&3
      else
        printf '      |'
        printf '      |' >&3
      fi
    done
    let l==$index_max || {
      printf '\n|------'
      for l in $(_seq 1 $index_max); do
        printf '+------'
      done
      printf '|\n'
      printf '\n' >&3
    }
  done
  printf '\n\\------'
  for l in $(_seq 1 $index_max); do
    printf '+------'
  done
  printf '/\n'
}

# Generate new piece on the board
# inputs:
#         $board  - original state of the game board
#         $pieces - original number of pieces
# outputs:
#         $board  - new state of the game board
#         $pieces - new number of pieces

#Adds a random 2 or 4 value to the board on a random pos based on remainder val.
function generate_piece {
  while true; do
    let pos=RANDOM%fields_total
    let board[$pos] || {
      let value=RANDOM%10?2:4
      board[$pos]=$value
      last_added=$pos
      printf "Generated new piece with value $value at position [$pos]\n" >&3
      break;
    }
  done
  let pieces++
}

# perform push operation between two pieces
# inputs:
#         $1 - push position, for horizontal push this is row, for vertical column
#         $2 - recipient piece, this will hold result if moving or joining
#         $3 - originator piece, after moving or joining this will be left empty
#         $4 - direction of push, can be either "up", "down", "left" or "right"
#         $5 - if anything is passed, do not perform the push, only update number 
#              of valid moves
#         $board - original state of the game board
# outputs:
#         $change    - indicates if the board was changed this round
#         $flag_skip - indicates that recipient piece cannot be modified further
#         $board     - new state of the game board

#Makes pieces moves based on keystroke and keeps their record of their postitions
function push_pieces {
  case $4 in
    "up")
      let "first=$2*$board_size+$1"
      let "second=($2+$3)*$board_size+$1"
      ;;
    "down")
      let "first=(index_max-$2)*$board_size+$1"
      let "second=(index_max-$2-$3)*$board_size+$1"
      ;;
    "left")
      let "first=$1*$board_size+$2"
      let "second=$1*$board_size+($2+$3)"
      ;;
    "right")
      let "first=$1*$board_size+(index_max-$2)" #index max used for down and right stroke to ensure size not exceeded
      let "second=$1*$board_size+(index_max-$2-$3)"
      ;;
  esac
  #-z is to check for an empty string
  let ${board[$first]} || { 
    let ${board[$second]} && {
      if test -z $5; then #Here varaibles are checked as empty and then proceeded
        board[$first]=${board[$second]}
        let board[$second]=0
        let change=1
        printf "move piece with value ${board[$first]} from [$second] to [$first]\n" >&3
      else
        let moves++
      fi
      return
    }
    return
  }
  let ${board[$second]} && let flag_skip=1
  let "${board[$first]}==${board[second]}" && { 
    if test -z $5; then
      let board[$first]*=2
      let "board[$first]==$target" && end_game 1
      let board[$second]=0
      let pieces-=1
      let change=1
      let score+=${board[$first]}
      printf "joined piece from [$second] with [$first], new value=${board[$first]}\n" >&3
    else
      let moves++
    fi
  }
}
#Applies the push and calls the push pieces
function apply_push {
  printf "\n\ninput: $1 key\n" >&3
  for i in $(_seq 0 $index_max); do
    for j in $(_seq 0 $index_max); do
      flag_skip=0
      let increment_max=index_max-j
      for k in $(_seq 1 $increment_max); do
        let flag_skip && break
        push_pieces $i $j $k $1 $2 #params to the push pieces passed here (i,j,k local vars and $1 & $2 are params)
      done 
    done
  done
}
#checks the moves
function check_moves { 
  let moves=0
  apply_push up fake
  apply_push down fake
  apply_push left fake
  apply_push right fake
}

#Different keys that respond for same ops
function key_react {
  let change=0
  read -d '' -sn 1 
  test "$REPLY" = "$ESC" && {
    read -d '' -sn 1 -t1
    test "$REPLY" = "[" && {
      read -d '' -sn 1 -t1
      case $REPLY in
        A) apply_push up;;
        B) apply_push down;;
        C) apply_push right;;
        D) apply_push left;;
      esac
    }
  } || {
    case $REPLY in
      k) apply_push up;;
      j) apply_push down;;
      l) apply_push right;;
      h) apply_push left;;

      w) apply_push up;;
      s) apply_push down;;
      d) apply_push right;;
      a) apply_push left;;
    esac
  }
}
#Crates dir and outputs(saves) all data into it
function save_game {
  rm -rf "$config_dir"
  mkdir "$config_dir"
  echo "${board[@]}" > "$config_dir/board"
  echo "$board_size" > "$config_dir/board_size"
  echo "$pieces" > "$config_dir/pieces"
  echo "$target" > "$config_dir/target"
  echo "$log_file" > "$config_dir/log_file"
  echo "$score" > "$config_dir/score"
  echo "$first_round" > "$config_dir/first_round"
}
#Realoads the game from save file in the config_dir
function reload_game {
  printf "Loading saved game...\n" >&3

  if test ! -d "$config_dir"; then #Files exists and a dir
    return
  fi
  board=(`cat "$config_dir/board"`)
  board_size=(`cat "$config_dir/board_size"`)
  board=(`cat "$config_dir/board"`)
  pieces=(`cat "$config_dir/pieces"`)
  first_round=(`cat "$config_dir/first_round"`)
  target=(`cat "$config_dir/target"`)
  score=(`cat "$config_dir/score"`)

  fields_total=board_size*board_size
  index_max=board_size-1
}

#Handles all prints in the end game stage, including saving to the file in dir
function end_game {
  # count game duration
  end_time=$(date +%s) 
  let total_time=end_time-start_time
  
  print_board
  printf "Your score: $score\n"
  
  printf "This game lasted "

  `date --version > /dev/null 2>&1`
  if [[ "$?" -eq 0 ]]; then
      date -u -d @${total_time} +%T
  else
      date -u -r ${total_time} +%T
  fi
  
  stty echo
  let $1 && {
    printf "Congratulations you have achieved $target\n"
    exit 0
  }
  let test -z $2 && {
    read -n1 -p "Do you want to overwrite saved game? [y|N]: "
    test "$REPLY" = "Y" || test "$REPLY" = "y" && {
      save_game #Call save game is made should it be called on.
      printf "\nGame saved. Use -r option next to load this game.\n"
      exit 0
    }
    test "$REPLY" = "" && {
      printf "\nGame not saved.\n"
      exit 0
    }
  }
  printf "\nYou have lost, better luck next time.\033[0m\n"
  exit 0
}
#calls this help section should the pass params are invalid. Call made from below
function help {
  cat <<END_HELP
Usage: $1 [-b INTEGER] [-t INTEGER] [-l FILE] [-r] [-h]

  -b			specify game board size (sizes 3-9 allowed)
  -t			specify target score to win (needs to be power of 2)
  -l			log debug info into specified file
  -r			reload the previous game
  -h			this help

END_HELP
}

#Passes in cmd line params to alter shape, size and so on.
#parse commandline options
while getopts "b:t:l:rh" opt; do
  case $opt in
    b ) board_size="$OPTARG"
      let '(board_size>=3)&(board_size<=9)' || {
        printf "Invalid board size, please choose size between 3 and 9\n"
        exit -1 
      };;
    t ) target="$OPTARG"
      printf "obase=2;$target\n" | bc | grep -e '^1[^1]*$'
      let $? && {
        printf "Invalid target, has to be power of two\n"
        exit -1 
      };;
    r ) reload_flag="1";;
    h ) help $0
        exit 0;;
    l ) exec 3>$OPTARG;;
    \?) printf "Invalid option: -"$opt", try $0 -h\n" >&2
            exit 1;;
    : ) printf "Option -"$opt" requires an argument, try $0 -h\n" >&2
            exit 1;;
  esac
done


#Below handles the main game, the while loop then handles the main running game.
#init board
#Responsilbe for initializing the game and sets up vars and calls functions.
let fields_total=board_size*board_size
let index_max=board_size-1
for i in $(_seq 0 $fields_total); do board[$i]="0"; done
let pieces=0
generate_piece
first_round=$last_added
generate_piece

#load saved game if flag is set
if test $reload_flag = "1"; then
  reload_game
fi

while true; do
  print_board
  key_react
  let change && generate_piece
  first_round=-1
  let pieces==fields_total && {
   check_moves
   let moves==0 && end_game 0 #lose the game
  }
done
