#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

YNH_PHP_VERSION=7.3

extra_php_dependencies="php${YNH_PHP_VERSION}-xml php${YNH_PHP_VERSION}-imagick php${YNH_PHP_VERSION}-bcmath php${YNH_PHP_VERSION}-exif php${YNH_PHP_VERSION}-mbstring php${YNH_PHP_VERSION}-gd php${YNH_PHP_VERSION}-mysqli php${YNH_PHP_VERSION}-json php${YNH_PHP_VERSION}-zip"

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

readonly YNH_DEFAULT_COMPOSER_VERSION=1.10.17
# Declare the actual composer version to use.
# A packager willing to use another version of composer can override the variable into its _common.sh.
YNH_COMPOSER_VERSION=${YNH_COMPOSER_VERSION:-$YNH_DEFAULT_COMPOSER_VERSION}

# Execute a command with Composer
#
# usage: ynh_composer_exec [--phpversion=phpversion] [--workdir=$final_path] --commands="commands"
# | arg: -v, --phpversion - PHP version to use with composer
# | arg: -w, --workdir - The directory from where the command will be executed. Default $final_path.
# | arg: -c, --commands - Commands to execute.
ynh_composer_exec () {
    # Declare an array to define the options of this helper.
    local legacy_args=vwc
    declare -Ar args_array=( [v]=phpversion= [w]=workdir= [c]=commands= )
    local phpversion
    local workdir
    local commands
    # Manage arguments with getopts
    ynh_handle_getopts_args "$@"
    workdir="${workdir:-$final_path}"
    phpversion="${phpversion:-$YNH_PHP_VERSION}"

    COMPOSER_HOME="$workdir/.composer" \
        php${phpversion} "$workdir/composer.phar" $commands \
        -d "$workdir" --quiet --no-interaction
}

# Install and initialize Composer in the given directory
#
# usage: ynh_install_composer [--phpversion=phpversion] [--workdir=$final_path] [--install_args="--optimize-autoloader"] [--composerversion=composerversion]
# | arg: -v, --phpversion - PHP version to use with composer
# | arg: -w, --workdir - The directory from where the command will be executed. Default $final_path.
# | arg: -a, --install_args - Additional arguments provided to the composer install. Argument --no-dev already include
# | arg: -c, --composerversion - Composer version to install
ynh_install_composer () {
    # Declare an array to define the options of this helper.
    local legacy_args=vwa
    declare -Ar args_array=( [v]=phpversion= [w]=workdir= [a]=install_args= [c]=composerversion=)
    local phpversion
    local workdir
    local install_args
    local composerversion
    # Manage arguments with getopts
    ynh_handle_getopts_args "$@"
    workdir="${workdir:-$final_path}"
    phpversion="${phpversion:-$YNH_PHP_VERSION}"
    install_args="${install_args:-}"
    composerversion="${composerversion:-$YNH_COMPOSER_VERSION}"

    curl -sS https://getcomposer.org/installer \
        | COMPOSER_HOME="$workdir/.composer" \
        php${phpversion} -- --quiet --install-dir="$workdir" --version=$composerversion \
        || ynh_die "Unable to install Composer."

    # update dependencies to create composer.lock
    ynh_composer_exec --phpversion="${phpversion}" --workdir="$workdir" --commands="install --no-dev $install_args" \
        || ynh_die "Unable to update core dependencies with Composer."
}




# Install or update the main directory yunohost.multimedia
#
# usage: ynh_multimedia_build_main_dir
ynh_multimedia_build_main_dir () {
        local ynh_media_release="v1.2"
        local checksum="806a827ba1902d6911095602a9221181"

        # Download yunohost.multimedia scripts
        wget -nv https://github.com/YunoHost-Apps/yunohost.multimedia/archive/${ynh_media_release}.tar.gz 

        # Check the control sum
        echo "${checksum} ${ynh_media_release}.tar.gz" | md5sum -c --status \
                || ynh_die "Corrupt source"

    # Check if the package acl is installed. Or install it.
    ynh_package_is_installed 'acl' \
        || ynh_package_install acl

        # Extract
        mkdir yunohost.multimedia-master
        tar -xf ${ynh_media_release}.tar.gz -C yunohost.multimedia-master --strip-components 1
        ./yunohost.multimedia-master/script/ynh_media_build.sh
}

# Add a directory in yunohost.multimedia
# This "directory" will be a symbolic link to a existing directory.
#
# usage: ynh_multimedia_addfolder "Source directory" "Destination directory"
#
# | arg: -s, --source_dir= - Source directory - The real directory which contains your medias.
# | arg: -d, --dest_dir= - Destination directory - The name and the place of the symbolic link, relative to "/home/yunohost.multimedia"
ynh_multimedia_addfolder () {
    # Declare an array to define the options of this helper.
    declare -Ar args_array=( [s]=source_dir= [d]=dest_dir= )
    local source_dir
    local dest_dir
    # Manage arguments with getopts
    ynh_handle_getopts_args "$@"

    ./yunohost.multimedia-master/script/ynh_media_addfolder.sh --source="$source_dir" --dest="$dest_dir"
}
