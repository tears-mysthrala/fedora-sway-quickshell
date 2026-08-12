#!/usr/bin/env bash

init_state() {
  mkdir -p "$PROJECT_STATE_DIR/backups"
  touch "$PROJECT_STATE_DIR/managed-links.tsv" "$PROJECT_STATE_DIR/installed-packages.txt"
}

path_token() {
  printf '%s' "$1" | sed 's#^/##; s#[^A-Za-z0-9._-]#_#g'
}

ensure_managed_link() {
  local source=$1 destination=$2 backup token
  init_state
  mkdir -p "$(dirname -- "$destination")"

  if [[ -L $destination && $(readlink -- "$destination") == "$source" ]]; then
    return 0
  fi

  backup=''
  if [[ -e $destination || -L $destination ]]; then
    token=$(path_token "$destination")
    backup="$PROJECT_STATE_DIR/backups/$token"
    if [[ -e $backup || -L $backup ]]; then
      die "Backup already exists; refusing to overwrite: $backup"
    fi
    mv -- "$destination" "$backup"
    log INFO "Backed up $destination to $backup"
  fi

  ln -s -- "$source" "$destination"
  if ! grep -Fqx "$source"$'\t'"$destination"$'\t'"$backup" "$PROJECT_STATE_DIR/managed-links.tsv"; then
    printf '%s\t%s\t%s\n' "$source" "$destination" "$backup" >>"$PROJECT_STATE_DIR/managed-links.tsv"
  fi
}

record_installed_package() {
  init_state
  grep -Fqx "$1" "$PROJECT_STATE_DIR/installed-packages.txt" || printf '%s\n' "$1" >>"$PROJECT_STATE_DIR/installed-packages.txt"
}

