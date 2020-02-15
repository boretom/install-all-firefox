#!/bin/bash +x

default_github_user=boretom
if [[ "${GITHUB_USER}x" == "x" ]]; then
    echo -e "GITHUB_USER environment variable not set. Use default user '${default_github_user}'."
    GITHUB_USER=$default_github_user
fi
echo -e "Use ${GITHUB_USER}'s github repository as source"

# purpose: install multiple versions of Firefox on Mac
#

default_versions_current="66"

# to add new versions: add it to past_xxs string and add it to the all_version array
# array structure is <exact version> ""

all_versions=()

old_all_versions=(
           2.0.0.20 1.3.1           3.0.19   1.3.4.b2           3.5.19   1.5.4
           3.6.28   1.7.3           4.0.1    1.8.0b7            5.0.1    1.9.2
           6.0.2    1.9.2           7.0.1    1.9.2              8.0.1    1.9.2
           9.0.1    1.9.2           10.0.2   1.9.2              11.0     1.9.2
           12.0     1.9.2           13.0.1   1.10.6             14.0.1   1.10.6
           15.0.1   1.10.6          16.0.1   1.10.6             17.0.1   1.11.3
           18.0.2   1.11.3          19.0.2   1.11.3             20.0     1.11.3
           21.0     1.11.3          22.0     1.11.3             23.0.1   1.12.0
           24.0     1.12.0          25.0.1   1.12.0             26.0     1.12.0
           27.0.1   1.12.0          28.0     1.12.0             29.0.1   1.12.0
           30.0     2.0.6           31.0     2.0.6              32.0     2.0.6
           33.1.1   2.0.6           34.0     2.0.6              35.0.1   2.0.6
           36.0     2.0.6           37.0     2.0.8              38.0     2.0.9
           39.0     2.0.11          40.0     2.0.12             41.0     2.0.12
           42.0     2.0.13          43.0     2.0.13             44.0     2.0.13
           45.0     2.0.14          46.0     2.0.16             47.0     2.0.17
           48.0     2.0.17          49.0     2.0.17             50.0     2.0.18
           51.0     ""              52.0     ""                 53.0.3   ""
           54.0.1   ""              55.0.3   ""                 56.0.2   ""
           57.0.4   ""              58.0.2   ""                 59.0.3   ""
           60.0.2   ""              61.0     ""
           )
# for firefox versions < 51
firebug_versions=(
           ## 1.3.1    1.3.4.b2    1.5.4 1.7.3
                    1.8.0b7     1.9.2
           1.9.2    1.9.2       1.9.2
           1.9.2    1.9.2       1.9.2
           1.9.2    1.10.6      1.10.6
           1.10.6   1.10.6      1.11.3
           1.11.3   1.11.3      1.11.3
           1.11.3   1.11.3      1.12.0
           1.12.0   1.12.0      1.12.0
           1.12.0   1.12.0      1.12.0
           2.0.6    2.0.6       2.0.6
           2.0.6    2.0.6       2.0.6
           2.0.6    2.0.8       2.0.9
           2.0.11   2.0.12      2.0.12
           2.0.13   2.0.13      2.0.13
           2.0.14   2.0.16      2.0.17
           2.0.17   2.0.17      2.0.18
           ""       ""          ""
           ""       ""          ""
           ""       ""          ""
           ""       ""
           )

# Using data from http://gs.statcounter.com/
versions_usage_point_one="43 44 45 46 50"
versions_usage_point_two=""
versions_usage_point_three=""
versions_usage_point_four_up="47 48"

default_versions=""
tmp_directory="/tmp/firefoxes/"
bits_host="https://raw.githubusercontent.com/${GITHUB_USER}/install-all-firefox/master/bits/"
bits_directory="${tmp_directory}bits/"
dmg_host="http://ftp.mozilla.org/pub/mozilla.org/firefox/"

locale_default="en-US"

# Don't edit below this line (unless you're adding new version cases in get_associated_information)

versions="${1:-$default_versions}"
release_directory=""
dmg_file=""
sum_file=""
sum_file_type=""
sum_of_dmg=""
sum_expected=""
binary=""
short_name=""
nice_name=""
vol_name_default="Firefox"
release_name_default="Firefox"
release_type=""
binary_folder="/Contents/MacOS/"
uses_v2_signing=false

specified_locale=${2:-$locale_default}

ver_long=""
ver_minor=""
ver_major=0

if [[ "${3}" == "no_prompt" ]]; then
    no_prompt=true
else
    no_prompt=false
fi

if [[ "${4}" == "" ]]; then
    install_directory="/Applications/Firefoxes/"
else
    install_directory=$4
    install_directory_length=${#install_directory}-1
    if [ "${install_directory:install_directory_length}" != "/" ]; then
        install_directory="${install_directory}/"
    fi
fi

ask(){
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
        echo
        read -p "$1 [$prompt] " REPLY
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

# get the firefox version from the mozilla repo
# this function populates the all_versions array
#
# parameter : none
# return    : none
#
get_versions(){
    #all_releases="$(cat firefox.releases | egrep -o '/releases/[0-9.]+/' | sed 's$/releases/\([0-9.]*\)/$\1$' | sort -n)"
    all_releases="$( curl -C - -L --progress-bar ${dmg_host}releases/ | egrep -o '/releases/[0-9.]+/' | sed 's$/releases/\([0-9.]*\)/$\1$' | sort -n)"

    #all_versions=()
    i=0

    prev_release=0.0
    curr_release=0.0

    #for r in 50.2 55.8 56.2 56.8 56.9; do
    for r in $all_releases; do
        # get the latest of each major version
        next=${r%%.*}
        curr=${curr_release%%.*}
        # skip version below 4
        if [ $next -lt 4 ]; then
            # avoid the 3.5 anomaly, for now
            continue
        fi
        #echo "next: $next, curr: $curr"

        if [ $next -ne $curr ]; then
            # got a new major
            prev_release=$curr_release
            curr_release=$r
            ## echo "prev release: $prev_release, curr release: $curr_release"
            # add prev to array since that is the latest version of it
            if [[ "$prev_release" > "0.0" ]]; then
                all_versions[$i]=$prev_release
                i=$((++i))
            fi
        else
            # still on the same major but later minor
            # this depends on the release list being numeric sorted
            curr_release=$r
        fi
    done
    # add the last entry
    all_versions[$i]=$curr_release
    default_versions="${all_versions[*]}"
    ##echo "array: ${all_versions[@]}"
    ##echo "array: ${default_versions[@]}"
}

get_associated_information(){
    # Reset everything
    vol_name=$vol_name_default
    release_name=$release_name_default
    firebug_version=""

    # get the long/precise version number and the corresponding firebug (firefox <=50, 0 for the others)
    for ((j=0; j < ${#all_versions[@]}; j++)) do
        ##echo "checking on element: ${all_versions[$j]}, j: $j"
        ver_to_use=${all_versions[$j]}
        ver_long=$ver_to_use
        if [ -z "${ver_to_use##$1*}" ]; then
            firebug_version=${firebug_versions[$j]}

            # check if version is x.y or x.y.z
            # deletes everthing except the '.'
            tmp=${ver_to_use//[^.]}
            if [ ${#tmp} -eq 1 ]; then
                # e.g. 42.0
                ver_minor=${ver_long}
            elif [ ${#tmp} -eq 2 ]; then
                # e.g. 19.0.2
                ver_minor=${ver_long%.*}
            elif [ ${#tmp} -eq 3 ]; then
                # e.g. 2.0.0.20
                ver_minor=${ver_long%.*.*}
            fi
            ver_major=${ver_long%%.*}
            # echo "ver_long: ${ver_long}, ver_minor: ${ver_minor}, ver_major: ${ver_major}, firebug ${firebug_version}"
            break
        fi
    done
    if [ $ver_major -eq 0 ]; then
         error "    Invalid version specified!\n\n    Please choose one of:\n    all current $default_versions\n\n"
         error "    To see which versions you have installed, type:\n    ./firefoxes.sh status"
         exit 1
    fi

    release_directory="${ver_long}"
    dmg_file="Firefox ${ver_long}.dmg"
    if [ "$ver_minor" = "3.5" ] || [ "$ver_minor" = "3.6" ]; then
        short_name="fx${ver_minor/./-}"
    else
        short_name="fx${ver_major}"
    fi
    # sum_file: MD5SUMS <=41, SHA512SUMS >= 42
    if [ $ver_major -le 41 ]; then
        sum_file_type="md5"
        sum_file="MD5SUMS"
    else
        sum_file_type="sha512"
        sum_file="SHA512SUMS"
    fi
    # binary: 'firefox-bin' <= 6, 'firefox' >= 7
    binary="firefox"
    nice_name="Firefox ${ver_minor}"
    if [ $ver_major -le 6 ]; then
        binary="firefox-bin"
        nice_name="Firefox ${ver_minor}"
    fi
    if [ $ver_major -ge 34 ]; then
        uses_v2_signing=true
    fi
    # firebug_version was set in the for loop
    # firebug <= 50
    firebug_version_short=$(echo "${firebug_version}" | sed 's/\.[0-9a-zA-Z]*$//')
    firebug_root="http://getfirebug.com/releases/firebug/${firebug_version_short}/"
    firebug_file="firebug-${firebug_version}.xpi"
}
setup_dirs(){
    if [[ ! -d "$tmp_directory" ]]; then
        mkdir -p "$tmp_directory"
    fi
    if [[ ! -d "$bits_directory" ]]; then
        mkdir -p "$bits_directory"
    fi
    if [[ ! -d "$install_directory" ]]; then
        mkdir -p "$install_directory"
    fi
}
get_bits(){
    log "Downloading bits"
    current_dir=$(pwd)
    cd "$bits_directory"

    for i in setfileicon create_firefox_image_with_version box.png base.png base_firefox56.png; do
        if [[ ! -f "${i}" ]]; then
            curl -C - -L --progress-bar "${bits_host}${i}" -o "${i}"
            chmod +x "${i}"
        fi
    done
    if [[ ! -f "${short_name}.png" ]]; then
        new_icon="true"
        icon_file="${current_dir}/bits/${short_name}.png"
        if [[ -f $icon_file ]]; then
            cp -r $icon_file "${short_name}.png"
        else
            curl -C - -L --progress-bar "${bits_host}${short_name}.png" -o "${short_name}.png"
            fgrep 404 ${short_name}.png >/dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                # $? == 0 : file not found in the repo but the png file is written as text
                rm "${short_name}.png"
                type convert > /dev/null 2>&1
                if [[ $? -eq 0 ]]; then
                    ${current_dir}/bits/create_firefox_image_with_version "${ver_major}.0" "${short_name}.png"
                else
                    echo "[error] ${short_name}.png couldn't be found and can't be created automatically"
                    echo "        using default Firefox icon"
                    cp -f base_firefox56.png "${short_name}.png"
                fi
            fi
        fi
    fi
    if [[ ! -f "${short_name}.icns" || $new_icon == "true" ]]; then
        sips -s format icns "${short_name}.png" --out "${short_name}.icns" &> /dev/null
    fi
    if [[ ! -f "${install_directory}{$nice_name}.app/Icon" ]]; then
        if [[ ! -f "fxfirefox-folder.png" ]]; then
            curl -C - -L --progress-bar "${bits_host}fxfirefox-folder.png" -o "fxfirefox-folder.png"
        fi
        if [[ ! -f "fxfirefox-folder.icns" ]]; then
            sips -s format icns "fxfirefox-folder.png" --out "fxfirefox-folder.icns" &> /dev/null
        fi
        ./setfileicon "fxfirefox-folder.icns" "${install_directory}"
    fi
}
check_dmg(){
    if [[ ! -f "${tmp_directory}/${dmg_file}" ]]; then
        log "Downloading ${dmg_file}"
        download_dmg
    else
        get_sum_file
        case $sum_file_type in
            md5)
                sum_of_dmg=$(md5 -q "${tmp_directory}${dmg_file}")
                sum_expected=$(cat "${sum_file}-${short_name}" | grep "${locale}/${dmg_file}" | cut -c 1-32)
            ;;
            sha512)
                sum_of_dmg=$(openssl dgst -sha512 "${tmp_directory}${dmg_file}" | sed "s/^.*\(.\{128\}\)$/\1/")
                sum_expected=$(cat "${sum_file}-${short_name}" | grep "${sum_of_dmg}" | cut -c 1-128)
            ;;
            *)
                error "✖ Invalid sum type specified!"
            ;;
        esac
        if [[ "${sum_expected}" == *"${sum_of_dmg}"* ]]; then
            log "✔ ${sum_file_type} of ${dmg_file} matches"
        else
            error "✖ ${sum_file_type} of ${dmg_file} doesn't match!"
            log "Redownloading.\n"
            download_dmg
        fi
    fi
}
get_sum_file(){
    cd "${tmp_directory}"
    curl -C - -L --progress-bar "${dmg_host}releases/${release_directory}/${sum_file}" -o "${sum_file}-${short_name}"
}
download_dmg(){
    cd "${tmp_directory}"
    dmg_file_safe=$(echo "${dmg_file}" | sed 's/ /\%20/g')
    dmg_url="${dmg_host}releases/${release_directory}/mac/$locale/${dmg_file_safe}"
    log "Downloading from ${dmg_url}"
    if ! curl -C - -L --progress-bar "${dmg_url}" -o "${dmg_file}"
    then
        error "✖ Failed to download ${dmg_file}!"
    fi
}
download_firebug(){
    cd "${tmp_directory}"
    if [[ ! -f "${firebug_file}" ]]; then
        log "Downloading Firebug ${firebug_version}"
        if ! curl -C - -L --progress-bar "${firebug_root}${firebug_file}" -o "${firebug_file}"
        then
            error "✖ Failed to download ${firebug_file}"
        else
            log "✔ Downloaded ${firebug_file}"
        fi
    fi
}
prompt_firebug(){
    # Only do anything if we've got a firebug version
    if [[ "${firebug_version}" != "" ]]; then
        if [ ${no_prompt} == false ]; then
            if ask "Install Firebug ${firebug_version} for ${nice_name}?" Y; then
                download_firebug
                install_firebug
            fi
        else
            download_firebug
            install_firebug
        fi
    fi
}
install_firebug(){
    if [[ -f "${install_directory}${nice_name}.app${binary_folder}${binary}" ]]; then
        is_legacy="false"
        if [ "${short_name}" == "fx2" -o "${short_name}" == "fx3" -o "${short_name}" == "fx3-5" -o "${short_name}" == "fx3-6" ]; then
            is_legacy="true"
        fi
        if [ "${is_legacy}" == "true" ]; then
            ext_dir=$(cd $HOME/Library/Application\ Support/Firefox/Profiles/;cd $(ls -1 | grep ${short_name}); pwd)
        else
            if [ "${uses_v2_signing}" == "true" ];then
                ext_dir="${install_directory}${nice_name}.app/Contents/Resources/"
            else
                ext_dir="${install_directory}${nice_name}.app${binary_folder}"
            fi
        fi
        cd "${ext_dir}"
        if [ "${is_legacy}" != "true" ]; then
            if [[ ! -d "distribution" ]]; then
                mkdir "distribution"
            fi
            cd "distribution"
        fi
        if [[ ! -d "extensions" ]]; then
            mkdir "extensions"
        fi
        cd "extensions"
        ext_dir=$(pwd)
        if [[ "${is_legacy}" == "true" ]]; then
            cp -r "${tmp_directory}${firebug_file}" "${ext_dir}"
        else
            unzip -qqo "${tmp_directory}${firebug_file}" -d "${tmp_directory}${firebug_version}"
            cd "${tmp_directory}${firebug_version}"
            FILE="$(cat install.rdf)"
            for i in $FILE;do
                if echo "$i"|grep "urn:mozilla:install-manifest" &> /dev/null ; then
                    GET="true"
                fi
                if [ "$GET" = "true" ] ; then
                    if echo "$i"|grep "<em:id>" &> /dev/null; then
                        ID=$(echo "$i" | sed 's#.*<em:id>\(.*\)</em:id>.*#\1#')
                        GET="false"
                    elif echo "$i"|grep "em:id=\"" &> /dev/null; then
                        ID=$(echo "$i" | sed 's/.*em:id="\(.*\)".*/\1/')
                        GET="false"
                    fi
                fi
            done
            cd ..
            mv "${firebug_version}" "${ext_dir}/${ID}/"
        fi
        log "✔ Installed Firebug ${firebug_version}"
    else
        error "${nice_name} not installed so we can't install Firebug ${firebug_version}!"
    fi
}
mount_dmg(){
    echo Y | PAGER=true hdiutil attach -plist -nobrowse -readonly -quiet "${dmg_file}" > /dev/null
}
unmount_dmg(){
    if [[ -d "/Volumes/${vol_name}" ]]; then
        hdiutil detach "/Volumes/${vol_name}" -force > /dev/null
    fi
}
install_app(){
    if [[ -d "${install_directory}${nice_name}.app" ]]; then

        if [ ${no_prompt} == false ]; then
            if ask "Delete your existing ${nice_name}.app and reinstall?" Y; then
                log "Reinstalling ${nice_name}.app"
                remove_app
                process_install
            else
                log "Skipping reinstallation of ${nice_name}.app"
            fi
        else
            remove_app
            process_install
        fi
    else
        process_install
    fi
}
remove_app(){
    if rm -rf "${install_directory}${nice_name}.app"
    then
        log "✔ Removed ${install_directory}${nice_name}.app"
    else
        error "✖ Could not remove ${install_directory}${nice_name}.app!"
    fi
}
process_install(){
    cd "/Volumes/${vol_name}"
    if cp -r "${release_name}.app/" "${install_directory}${nice_name}.app/"
    then
        log "✔ Installed ${nice_name}.app"
    else
        unmount_dmg
        error "✖ Could not install ${nice_name}.app!"
    fi
    unmount_dmg
    create_profile
    modify_launcher
    install_complete
}
create_profile(){
    if exec "${install_directory}${nice_name}.app${binary_folder}${binary}" -CreateProfile "${short_name}" &> /dev/null &
    then
        log "✔ Created profile '${short_name}' for ${nice_name}"
    else
        error "✖ Could not create profile '${short_name}' for ${nice_name}"
    fi
}
modify_launcher(){
    plist_old="${install_directory}${nice_name}.app/Contents/Info.plist"
    plist_new="${tmp_directory}Info.plist"
    sed -e "s/${binary}/${binary}-af/g" "${plist_old}" > "${plist_new}"
    mv "${plist_new}" "${plist_old}"

# No indentation while catting
cat > "${install_directory}${nice_name}.app${binary_folder}${binary}-af" <<EOL
#!/bin/sh
"${install_directory}${nice_name}.app${binary_folder}${binary}" -no-remote -P ${short_name} &
EOL

    chmod +x "${install_directory}${nice_name}.app${binary_folder}${binary}-af"

# tell all.js where to find config

if [[ "${uses_v2_signing}" == "true" ]]; then
    config_dir="${install_directory}${nice_name}.app/Contents/Resources/"
else
    config_dir="${install_directory}${nice_name}.app${binary_folder}"
fi
prefs_dir="${config_dir}defaults/pref/"
# fx34 doesn't move the mozilla.cfg yet...
if [[ "${short_name}" == "fx34" ]]; then
    config_dir="${install_directory}${nice_name}.app${binary_folder}"
fi

mkdir -p "${prefs_dir}"
prefs_file="${prefs_dir}all.js"

cat > "${prefs_file}" <<EOL
pref("general.config.obscure_value", 0);
pref("general.config.filename", "mozilla.cfg");
EOL

# make config
config_file="${config_dir}mozilla.cfg"
cat > "${config_file}" <<EOL
// IMPORTANT: always start on 2. line
// https://support.mozilla.org/en-US/kb/customizing-firefox-using-autoconfig
lockPref("browser.shell.checkDefaultBrowser", false);
lockPref("browser.startup.homepage_override.mstone", "ignore");
lockPref("app.update.enabled", false);
lockPref("browser.rights.3.shown", false);
lockPref("toolkit.telemetry.prompted", 2);
lockPref("toolkit.telemetry.rejected", true);
EOL

# Firefox 63 and later changed disabling app update
# https://github.com/mozilla/policy-templates/blob/master/README.md
# check for "DisableAppUpdate" section
#
# tl;dr: create a file policies.json in 'Resources/distribution' with the below content
if [ $ver_major -gt 62 ]; then
    mkdir -p "${config_dir}distribution"
    cat > "${config_dir}distribution/policies.json" <<EOL
{ "policies": { "DisableAppUpdate": true } }
EOL
fi

    cd "${bits_directory}"
    ./setfileicon "${short_name}.icns" "${install_directory}/${nice_name}.app/"
}
install_complete(){
    log "✔ Install complete!"
}
error(){
    printf "\033[31m%b\033[00m " $*
    printf "\n"
    return 0
}
log(){
    printf "\033[32m%b\033[00m " $*
    printf "\n"
    return $?
}

# get the available version from the big 'ol internet
get_versions
# Replace special keywords with actual versions (duplicates are okay; it'll work fine)
versions=${versions/all/${default_versions}}
versions=${versions/current/${default_versions_current}}
versions=${versions/latest/${default_versions_current}}
versions=${versions/newest/${default_versions_current}}
versions=${versions/min_point_one/${versions_usage_point_one} ${versions_usage_point_two} ${versions_usage_point_three} ${versions_usage_point_four_up}}
versions=${versions/min_point_two/${versions_usage_point_two} ${versions_usage_point_three} ${versions_usage_point_four_up}}
versions=${versions/min_point_three/${versions_usage_point_three} ${versions_usage_point_four_up}}
versions=${versions/min_point_four/${versions_usage_point_four_up}}

if [[ $versions == 'status' ]]; then
    printf "The versions in \033[32mgreen\033[00m are installed, \033[1;32mlight green\033[00m means there's an updated version available:\n"
    for VERSION in $default_versions; do
        get_associated_information $VERSION
        app_path="${install_directory}${nice_name}.app"
        version_str="$VERSION"
        if [ ${ver_major} -lt 34 ]; then
            version_file_path=${app_path}/Contents/MacOS/application.ini
        else
            version_file_path=${app_path}/Contents/Resources/application.ini
        fi
        if [ -d "${app_path}" ]; then
            # get installed version
            version_installed=$(sed -ne "s/^Version=\([0-9.]\{1,\}\)/\1/p" "${version_file_path}")
            # check if there's an update available
            if [ ${version_installed//./} -lt ${ver_long//./} ]; then
                # light green if found but never version available
                output_color="\033[1;32m"
                version_str="installed: ${version_installed}, latest: $VERSION"
            else
                # regular green if installed
                output_color="\033[32m"
            fi
        else
            # color for not installed == red
            output_color="\033[31m"
        fi
        printf "\n${output_color} - ${nice_name} (${version_str})\033[00m"
    done
    printf "\n\nTo install, type \033[1m./firefoxes.sh [version]\033[22m, \nwith [version] being the number or name in parentheses\n\n"
    exit 1
fi

get_locale() {
    all_locales=" af ar be bg ca cs da de el en-GB en-US es-AR es-ES eu fi fr fy-NL ga-IE he hu it ja-JP-mac ko ku lt mk mn nb-NO nl nn-NO pa-IN pl pt-BR pt-PT ro ru sk sl sv-SE tr uk zh-CN zh-TW "

    # ex: "fr-FR.UTF-8" => "fr-FR"
    cleaned_specified_locale=$(echo ${specified_locale/_/-} | sed 's/\..*//')
    cleaned_system_locale=$(echo ${LANG/_/-} | sed 's/\..*//')

    # ex: "fr-FR" => "fr"
    cleaned_system_locale_short=$(echo $cleaned_system_locale | sed 's/-.*//')

    # Will make something more scalable if needed later
    # But for now, we make these locales use en-US
    if [[ $cleaned_system_locale == 'en-AU' || $cleaned_system_locale == 'en-CA' ]]; then
        echo "Your system locale is set to ${cleaned_system_locale}. As there is no ${cleaned_system_locale} localization available for Firefox, en-US has been used instead."
        cleaned_system_locale='en-US'
    fi

    if [[ $all_locales != *" $cleaned_system_locale "* && $all_locales == *" $cleaned_system_locale_short "* ]]; then
        echo "Your system locale \"$cleaned_system_locale\" is not available, but \"$cleaned_system_locale_short\" is!"
        echo "We'll use \"$cleaned_system_locale_short\" as the default locale if you've not specified a valid locale."
        cleaned_system_locale=$cleaned_system_locale_short
    fi

    if [[ -n $specified_locale ]]; then
        if [[ $all_locales != *" $cleaned_specified_locale "* ]]; then
            echo "\"${cleaned_specified_locale}\" was not found in our list of valid locales."
            locale=$cleaned_system_locale
        else
            locale=$cleaned_specified_locale
        fi
    else
        locale=$cleaned_system_locale
    fi

    echo "We're using ${locale} as your locale."

    echo "If this is wrong, use './firefoxes.sh [version] [locale]' to specify the locale."
    echo ""
    echo "The valid locales are:"
    echo " ${all_locales}"
}

clean_up() {
    if ask "Delete all files from temp directory (${tmp_directory})?" Y; then
        log "Deleting temp directory (${tmp_directory})!"
        rm -rf ${tmp_directory}
    else
        log "Keeping temp directory (${tmp_directory}), though it will be deleted upon reboot!\n"
    fi
    return 0
}

## 'main' starts here
if [ "$(uname -s)" != "Darwin" ]; then
    error "This script is designed to be run on OS X\nExiting..."
    exit 0
fi

get_locale

for VERSION in $versions; do
    ##echo "get assoc for version : $VERSION"
    get_associated_information $VERSION
    log "====================\nInstalling ${nice_name}"
    setup_dirs
    get_bits
    check_dmg
    mount_dmg
    install_app
    unmount_dmg
    prompt_firebug
done

clean_up
