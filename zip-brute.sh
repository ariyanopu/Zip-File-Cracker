#!/usr/bin/env bash

# Color codes (use actual escape characters)
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
PURPLE=$'\e[1;35m'
CYAN=$'\e[1;36m'
NC=$'\e[0m' # No Color

# Clear screen in a portable way
clear_screen() {
  printf "\033c" 2>/dev/null || clear
}

# Block-style loader 0% -> 100%
loading_bar() {
  clear_screen
  local total_blocks=20
  local sleep_per_step=0.02  # adjust to make loader faster/slower
  printf "%b\n\n" "${CYAN}Initializing Tool...${NC}"
  for percent in $(seq 0 1 100); do
    filled=$(( percent * total_blocks / 100 ))
    empty=$(( total_blocks - filled ))
    bar=""
    for ((i=0;i<filled;i++)); do bar+="■"; done
    for ((i=0;i<empty;i++)); do bar+="□"; done
    printf "\r%b %3d%%  [%b]" "${CYAN}Loading:" "$percent" "$bar"
    sleep "$sleep_per_step"
  done
  printf "\n\n"
  sleep 0.15
  clear_screen
}

# Banner
show_banner() {
  printf "%b" "${GREEN}"
  echo "   ▀▀▌▗    ▞▀▖         ▌        "
  echo "    ▞ ▄ ▛▀▖▌  ▙▀▖▝▀▖▞▀▖▌▗▘▞▀▖▙▀▖"
  echo "   ▞  ▐ ▙▄▘▌ ▖▌  ▞▀▌▌ ▖▛▚ ▛▀ ▌  "
  echo "   ▀▀▘▀▘▌  ▝▀ ▘  ▝▀▘▝▀ ▘ ▘▝▀▘▘  "
  printf "%b" "${NC}"
  printf "%b\n" "${PURPLE}=============================================${NC}"
  printf "%b\n" "${CYAN}           ZIP Password Cracker${NC}"
  printf "%b\n" "${PURPLE}=============================================${NC}"
  printf "%b\n" "${YELLOW}          Created by Ariyan Mirza${NC}"
  printf "%b\n" "${BLUE}       GitHub: github.com/ariyanopu${NC}"
  printf "%b\n\n" "${PURPLE}=============================================${NC}"
}

# Help menu
show_help() {
  show_banner
  printf "%b\n" "${YELLOW}Usage:${NC}"
  echo "  $0 <zip_file> [wordlist]"
  printf "\n%b\n" "${YELLOW}Options:${NC}"
  echo "  <zip_file>    Path to password protected ZIP file (required)"
  echo "  [wordlist]    Path to wordlist file (default: password.txt or interactive choice)"
  printf "\n%b\n" "${YELLOW}Examples:${NC}"
  echo "  $0 secret.zip passwords.txt"
  echo "  $0 secret.zip (uses default password.txt)"
  echo "  $0           (interactive mode)"
  exit 1
}

# Typing animation for "Cracking Start"
typing_animation() {
  local text="Cracking Start"
  for ((i=0; i<${#text}; i++)); do
    printf "%s" "${text:i:1}"
    sleep 0.06
  done
  printf "\n\n"
}

# Show "new session" (clear + banner + small message)
start_new_session() {
  clear_screen
  show_banner
  printf "%b\n" "${CYAN}[i] New Session Started${NC}"
  sleep 0.25
}

# Main cracking function
crack_zip() {
  local zip_file=$1
  local wordlist=$2

  if [ ! -f "$wordlist" ]; then
    printf "%b\n" "${RED}[!] Wordlist not found: $wordlist${NC}"
    return 1
  fi

  total_passwords=$(wc -l < "$wordlist" 2>/dev/null || echo 0)
  if ! [[ "$total_passwords" =~ ^[0-9]+$ ]]; then total_passwords=0; fi
  if [ "$total_passwords" -le 0 ]; then
    printf "%b\n" "${RED}[!] Wordlist is empty or unreadable: $wordlist${NC}"
    return 1
  fi

  current_password=0
  found=0

  start_new_session
  printf "%b\n" "${GREEN}[+] Target: ${zip_file}${NC}"
  printf "%b\n" "${YELLOW}[i] Using wordlist: ${wordlist}${NC}"
  printf "%b\n\n" "${YELLOW}[i] Total passwords to try: ${total_passwords}${NC}"
  printf "%b\n" "${PURPLE}=============================================${NC}"

  # Typing animation then real start
  typing_animation

  start_time=$(date +%s)

  while IFS= read -r password || [ -n "$password" ]; do
    current_password=$((current_password + 1))
    percentage=$(( current_password * 100 / total_passwords ))

    # Progress bar (scaled to 50 chars)
    total_bar=50
    filled=$(( percentage * total_bar / 100 ))
    empty=$(( total_bar - filled ))

    filled_str=""
    empty_str=""
    for ((i=0; i<filled; i++)); do filled_str+="■"; done
    for ((i=0; i<empty; i++)); do empty_str+=" "; done

    left="${CYAN}["
    middle="${filled_str}${empty_str}"
    right="${CYAN}]"

    printf "\r%b%3d%% %b" "${left}${middle}${right} " "$percentage" "${YELLOW}Trying: '$password'${NC}"

    # Try password (unzip -t -P)
    if unzip -t -P "$password" "$zip_file" >/dev/null 2>&1; then
      found=1
      end_time=$(date +%s)
      duration=$((end_time - start_time))
      printf "\n\n%b\n" "${GREEN}[✓] PASSWORD FOUND: '${password}'${NC}"
      printf "%b\n" "${GREEN}[✓] Time taken: ${duration} seconds${NC}"
      printf "%b\n" "${GREEN}[✓] Attempts: ${current_password}/${total_passwords}${NC}"
      printf "%b\n" "${PURPLE}=============================================${NC}"
      break
    fi

  done < "$wordlist"

  if [ $found -eq 0 ]; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    printf "\n\n%b\n" "${RED}[✗] PASSWORD NOT FOUND IN WORDLIST${NC}"
    printf "%b\n" "${YELLOW}[i] Time taken: ${duration} seconds${NC}"
    printf "%b\n" "${YELLOW}[i] Total attempts: ${current_password}${NC}"
    printf "%b\n" "${PURPLE}=============================================${NC}"
    return 2
  fi

  return 0
}

# Function to build a combined wordlist from ./wordlists/*.txt
build_combined_wordlist_from_folder() {
  local folder="./wordlists"
  if [ ! -d "$folder" ]; then
    return 1
  fi

  shopt -s nullglob
  files=("$folder"/*.txt)
  shopt -u nullglob

  if [ ${#files[@]} -eq 0 ]; then
    return 2
  fi

  tmp_combined=$(mktemp)
  # Combine, remove blank lines and duplicates
  cat "${files[@]}" | awk 'NF' | sort -u > "$tmp_combined"
  if [ ! -s "$tmp_combined" ]; then
    rm -f "$tmp_combined"
    return 3
  fi

  echo "$tmp_combined"
  return 0
}

# Main execution
main() {
  loading_bar

  if [ $# -ge 1 ]; then
    zip_file="$1"
    if [ $# -ge 2 ]; then
      wordlist="$2"
    else
      wordlist="${2:-password.txt}"
    fi

    if [ ! -f "$zip_file" ]; then
      printf "%b\n" "${RED}[!] ZIP file not found: $zip_file${NC}"
      show_help
    fi

    if [ ! -f "$wordlist" ]; then
      printf "%b\n" "${RED}[!] Wordlist not found: $wordlist${NC}"
      show_help
    fi

    start_new_session
    crack_zip "$zip_file" "$wordlist"
    exit $?
  fi

  # Interactive mode
  start_new_session
  read -rp $'\nEnter File Path: ' zip_file
  if [ -z "$zip_file" ]; then
    printf "%b\n" "${RED}[!] You must provide a ZIP file path.${NC}"
    exit 1
  fi
  if [ ! -f "$zip_file" ]; then
    printf "%b\n" "${RED}[!] ZIP file not found: $zip_file${NC}"
    exit 1
  fi

  echo -e "\nDo You Crack Custom Password"
  echo -e "[1] Yes"
  echo -e "[2] No"

  read -rp $'\nChoose option [1/2]: ' opt
  case "$opt" in
    1)
      read -rp $'\nPassword File Path: ' wordlist
      if [ -z "$wordlist" ] || [ ! -f "$wordlist" ]; then
        printf "%b\n" "${RED}[!] Wordlist not found or unreadable: $wordlist${NC}"
        exit 1
      fi
      crack_zip "$zip_file" "$wordlist"
      ;;
    2)
      # Try to build combined from ./wordlists
      combined_path=$(build_combined_wordlist_from_folder)
      rc=$?
      if [ $rc -eq 0 ] && [ -n "$combined_path" ]; then
        # got combined wordlist
        crack_zip "$zip_file" "$combined_path"
        rm -f "$combined_path"
      else
        # fallback: check for ./password.txt in main folder
        if [ -f "./password.txt" ]; then
          printf "%b\n" "${YELLOW}[i] ./wordlists missing or empty. Falling back to ./password.txt${NC}"
          crack_zip "$zip_file" "./password.txt"
        else
          printf "%b\n" "${RED}[!] Could not build combined wordlist and ./password.txt not found.${NC}"
          printf "%b\n" "${YELLOW}[i] Make sure either ./wordlists/*.txt exists or place password.txt in the project root.${NC}"
          exit 1
        fi
      fi
      ;;
    *)
      printf "%b\n" "${RED}[!] Invalid option.${NC}"
      exit 1
      ;;
  esac
}

main "$@"
