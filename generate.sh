#!/bin/bash -e

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/acl.XXXXXX)

GFWLIST_URL="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
CHNROUTE_URL="https://pexcn.me/daily/chnroute/chnroute.txt"
CHNROUTE_V6_URL="https://pexcn.me/daily/chnroute/chnroute-v6.txt"

fetch_data() {
  cd $TMP_DIR
  curl -sSL --connect-timeout 10 $GFWLIST_URL -o gfwlist.txt
  curl -sSL --connect-timeout 10 $CHNROUTE_URL -o chnroute.txt
  curl -sSL --connect-timeout 10 $CHNROUTE_V6_URL -o chnroute-v6.txt
  cd $CUR_DIR
}

gen_gfwlist_acl() {
  cd $TMP_DIR
  python $CUR_DIR/parse.py -i gfwlist.txt -f gfwlist.tmp
  sed -i 's/.*\((?:^|\\.)blogspot\\.\).*/\(?:^|\\.)blogspot(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?){1,2}$/' gfwlist.tmp
  sed -i 's/.*\((?:^|\\.)google\\.\).*/\(?:^|\\.)google(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?){1,2}$/' gfwlist.tmp
  sed -i 's/.*\((?:^|\\.)googleapis\\.\).*/\(?:^|\\.)googleapis(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?){1,2}$/' gfwlist.tmp
  uniq gfwlist.tmp > gfwlist.acl
  cd $CUR_DIR
}

gen_chinalist_acl() {
  cd $TMP_DIR
  cp $CUR_DIR/template/china-list.acl .
  sed -i "s/___CHNROUTE_PLACEHOLDER___/cat chnroute.txt/e" china-list.acl
  cd $CUR_DIR
}

gen_bypass_acls() {
  cd $TMP_DIR
  cp $CUR_DIR/template/bypass-china.acl .
  cp $CUR_DIR/template/bypass-lan-china.acl .
  sed -e "1,/proxy_list/d" gfwlist.acl > proxylist.txt
  sed -i "s/___CHNROUTE_PLACEHOLDER___/cat chnroute.txt/e" bypass-china.acl bypass-lan-china.acl
  sed -i "s/___CHNROUTE_V6_PLACEHOLDER___/cat chnroute-v6.txt/e" bypass-china.acl bypass-lan-china.acl
  sed -i "s/___GFWLIST_PLACEHOLDER___/cat proxylist.txt/e" bypass-china.acl bypass-lan-china.acl
  cd $CUR_DIR
}

dist_release() {
  mkdir -p release/acl
  cp $TMP_DIR/gfwlist.acl release/acl/
  cp $TMP_DIR/china-list.acl release/acl/
  cp $TMP_DIR/bypass-china.acl release/acl/
  cp $TMP_DIR/bypass-lan-china.acl release/acl/
  cp template/bypass-lan.acl release/acl/
}

fetch_data
gen_gfwlist_acl
gen_chinalist_acl
gen_bypass_acls
dist_release
