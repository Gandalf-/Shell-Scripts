#!/bin/bash

# Script that compresses and encrypts directories with openssl and zip
# also handles the reverse process to restore the files. Works on files and
# directories, don't have to be in the current working directory
#
# requires openssl, zip


# zip and then aes256 encrypt
function encrypt() {

  # try to catch attempted re-encryption
  if [[ ${file: -8} == ".zaes256" ]] ; then
    echo "$file appears to already be encrypted"
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo

    if test "$REPLY" != "y" ; then
      exit
    fi
  fi

  # compress the directory with zip
  zip -r "$file".zip "$file" >/dev/null
  if test "$?" != 0 ; then
    echo "Compression failed, not continuing"
    exit
  fi

  # encrypt with openssl and aes256
  openssl aes256 -in "$file".zip -out "$file".zaes256 -salt
  if test "$?" != 0 ; then
    echo "Encryption failed, not continuing"
    rm -r "$file".zip
    exit
  fi

  # set output to read only and cleanup working files
  chmod 400 "$file".zaes256
  rm -rf "$file" "$file".zip 
  if test "$?" != 0 ; then
    echo "Cleanup failed, please check the directory for extra files"
    exit
  fi

  echo "Encryption completed. Output file is $file.zaes256"
}

# aes256 decrypt and unzip
function decrypt() {

  # try to catch attempted re-encryption
  if [[ ${file: -8} != ".zaes256" ]] ; then
    echo "$file doesn't appear to be encrypted by cryptdir"
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r
    echo

    if test "$REPLY" != "y" ; then
      exit
    fi
  fi

  # decrypt with openssl
  openssl aes256 -d -in "$file" -out "$file".zip -salt
  if test "$?" != 0 ; then
    echo "Decryption failed, not continuing"

    if [[ -e "$file".zip ]] ; then
      rm "$file".zip
    fi

    exit
  fi

  # decompress the output
  unzip "$file".zip >/dev/null
  if test "$?" != 0 ; then
    echo "Decompression failed, not continuing"
    exit
  fi

  # clean up the working files
  rm -rf "$file" "$file".zip
  if test "$?" != 0 ; then
    echo "Cleanup failed, please check the directory for extra files"
    exit
  fi

  echo "Decryption completed."
}

# check input, and for required files
if test "$1" == "" ; then
  echo "Usage: cryptdir filename"
  exit

elif ! [[ -e $1 ]] ; then
  echo "File provided does not exist, not continuing"
  exit

elif test "$(which openssl)" == "" ; then
  echo "Could not find required program: openssl"
  exit

elif test "$(which zip)" == "" ; then
  echo "Could not find required program: zip"
  exit

else
  file=$1
fi

# choose action
read -p "encrypt or decrypt (e/d) ? " -n 1 -r
echo

if test "$REPLY" == 'e' ; then
  encrypt

elif test "$REPLY" == 'd' ; then
  decrypt

else
  echo "Must specify e or d"
  exit
fi
