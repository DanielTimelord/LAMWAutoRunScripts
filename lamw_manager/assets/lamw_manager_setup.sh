#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3703434657"
MD5="a2957e284036353635ad96c76d099d6d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20360"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 592 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=copy
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 08:30:41 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
    \"--copy\" \\
    \"--target\" \\
    \"$HOME/lamw_manager\" \\
    \"/tmp/lamw_manager_build\" \\
    \"lamw_manager_setup.sh\" \\
    \"LAMW Manager Setup\" \\
    \"./.start_lamw_manager\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"$HOME/lamw_manager\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=128
	echo OLDSKIP=593
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 592 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
� �i�]�<�v�F�~%��2G��nN� �IɌ%�KR�3�H4)X�
�#q�3F�A;P Ufz@T�ԅ��+Y��â���D5�ꄖQ]��F#�x7a1�e�kJA�����O�ЫA���'sh�7e ����ch�M��ٹ2��!ǴȵD.����d�f��u�v�_���U�H�m`1	\C2���`�L�
�٤=��$}<�<B�*�$U�.��G>�{n�0v��W�z�� ��$/�~T̯��uT�`���������]���f�Q��o���*?��a�K����Ik�È�W����Ά����$���o������a a�ɣ0��{2�g݁Lb�خa�M�I �a|ܔ�eA=_X��=�g"��*���Ы��#U�C��(�mP˴ML:w��~A��D�!���wm0� ��V��AtL�{�<<�����_�� ���lV�Vy�@>C�ʑ�מ�0ў�1���M����f!�t(p�N�*�a?�^�x�E��V?
���״����oV�o6w��_s�gXxU��iԯ����fo/���ƣ���f���nn�����g � a�:���� �L�o�,�C}vB���G����3��Vk�~�����c��i|%�.U
�'[�Ƥ!g0��q�`2h��k�2_��)�P�X��(C��I���"�a���u5�މ_v��^�T��� ��Zf��rQl��\�~В��]�bwr/����	h����,�pi]I����$��4s�E�0��)�U�sS T�~pѥ�u�{�N}s��	�@�A/y����&@�a�=��O˜�|�
����
��˃?]�r	�W�W,�3�����ft7����K�u��չ9;Gn��*J�FT)�k�A2ш,/���c.rTY5���z�2�_�*�x���ɸ�B�K+$���BZ��$<B'�Ӎ�g�/Hb��8
��9�r���m��\���M��j�Km߾U���PGG1؟{���t��wz�z�����u�Nay���`�<���q,��ݫ:�c}�\��DK�O��vy�w%��h#��R|jUq�Sº��<ɩc�-� 	�<D4d�CxAe�(��b��F�@(&<\����qN˷�)��,hzn��P�[�2cݥ
�6�,<z_��`9���kˤ=8��[ã�X���cMV�$v�e�%�"�"�a4�m�^>k�=y8x�%�X���a﵆;S\���F�J!M��DE*靄�8�φ���hFËX1D��_�Aȇ�L/f�<YI���f׻�G���s[#oA��i��w�:�"]�w�=rhYf�����nO�Ó��L��2!���R�K_N�Mk��/ch�NS���r���/e�2P�̾�
.gV���Z���D�{VZ��|w�Tb�J�;�����_"�y�x~�$�e��'P+�g<@��&%�xԈ��`I�X�|�_�&|*����}H�G��#9�sA����h�n#�a��C��� +��
�!ާ�C\���4�(ȩ�&��Q��|" �y�, g1+��*�
�׵ ��Z-'j�����C�@�"��J0�ʚr��\
����0�b����'�P�~�?���.������
����I�J*��"�9k���T��z=/�ֲ��)���GyT܁ =��c��B7!�������	�;0 1����5�͟j��s�<}w�o~��0��ءA�3��e,ޘ½�'Q��c��.�=�ʕox�s�%2��.�v�t�.z�1�2��D�Z�Fn�\YB�;�"� &�*�&��|$.��L*�ɡQY+���=g���ʢ4�q�^�L���+׿`�>�s_��/FwS���G��f�3.Čq�i���[���Es����w�^�Vh���gxg�1��?s=����(�Zj‧��y\�wf/�2��P؈��d�FQ$&���`���{DI;�eSA��W[ǯ
�Z��X�z��`��u��:�C�>��#8�}���<��@F�A6z���Zy��*���Kڽ(�]��9
0,�
�����֓�I�8��J;`�9\�'���Ÿ?�� �Ý���&�t���sN-��p\�򻎺r��P[��"4
�I�n�����,(�ʽZf��ā� ��^����i��5������J��?��rT`�S�@8�E�
�/@0�?��i-�����Ah����R���	�2�Ql|����xf��a�� |Q-�L�����u ����ב�=g�����K3���D䐡eEl�!\�����h�mF�vdq@�,u��l">�Y�F<�_!9�>u.�V�ɬf�������)�c��8��}r�$*/�:ſ��f(����eα�E^q�Vh�L�E����:�������bc��eN%���geN����C�G�����V���w<r|�y���y/(||)+��w6��rR�QW7
�u}#�c�%̩`|��O�P>�1���7���i|P�g��3�IQ`��z��Q���D|�1��b�b��m O�������m�mY������Ij� �K��z(���- �v��@�"Un[P��ڿ3��2�0��?�璙�Y��4�vϒ�
yϓ��'��N`>m�W5��Z��_�ก�ɮ���%����u�K�[rJִZ�WzT
�Q1Ӆc࿆F��C��\gi��,�Gӷ��J��W(��z��}�J�����wc��*��ۧK忊��i�T���3P��
�^٘���(QE����9�nS-��*�ެ~�a���_�3��~a�\9S������F�2�1�E�i��۫Be.��rm���ό�Vt7Vk�?b��?����D�rbC�9�&�+|=�J��XUuV��(L�C�^M��0'�S�%��xHD�>��E�t����nF*�fu�Z����[�њ��dG�l$�f2��TZ��2�����ᦋZ%�7�I�;N�|H�_�{5��a�?	�;�ǌ��?xxJ���7�N���ݏ./�_�����e#��vn|��7X�BZ ��j0JX'���s��(���
�y�OY��]�d+"��'����
� ��}�x��i������%R�vJ8�y}7Èp�[\��6��S��n�J~�Q\e�4:U�1����K�"IF�-��9۰X-Yɋ�kiS�Rm���<'>w緈�:Pv�ۊV'M�p!)�2d(�����PI�/r���b 9y_,�^.�x�O�I���Oo}pb�+�,��ܥ�ȝ�L�H���%TĬ���*5Je槉�޷�ɀPńАx~��ƻ���M4�]+$��r�T�;_|�&ܨdŒ����R�C��ѕ��X�Q:M.f�>k�!���n����z�N/7��]�EDZJ/�Ί0� ��s��.���x+yy�������D��o<��<Ho9��h�<�
v17A,����,�=����v���p� �H���OF$ɽ�%�vP��Y�CB���+(��uZ���Go:�)=/g�{ۡ%,}2��s�~�q���35M	��5���+���O�F�l9!�&�����y���.�ծ��[$��;�ɐ|�{#�$�e��0)o�d�%YVI�(i�M�ݘ$e-���L��
��t�ԯ�U���΢�$�ݥ��Uʎ�B�(�"�ї���Sg�`�c�Ze��sqF�,P�&�{���te��~8������B�ce��׫>� z�>l2M���u������������:��#T�?&0��b��}~����i�1~��ގ�a�`WjR9M��OH�eI"�oC]Vў�f~^s�����d_LM�,����T�
ӂ�\0���P.^N�؞40��֑�|n`��+L�d2���l�Z^Sև|�K��0�g��	�u� ha�٘�ɂ�;/���|���ʺ�rVJ��Xj
���5
�`.����.`����C����u�8�L},���틑9E��x*7������I���<�W
��|%��қ�㗻���>
v�\퇽����E���!��U����|Ĉ�Z��G��5r�P�����o�{���}1D��hDA�(�"tj+O�Fl�~K�b-̓�`_���Ky�x����?�.��/��辌	�DV^�F����G�c�C��\�n�Hͅ ��t`�^��T��+Mg��i�9���b��� ���ځ�!�����գ�֪�f6��r#CϤ�{����D��9!c9�mڱ���>(X�E1*+��$�&?����$x)�������DI����w��Q��e����k�rQx�(� ����u/�Q�)��S0[�P�����k�	��?d�h�xQY<�tkɓ���B����Ƅ֕�?�g�v^����&�L�Rb@ɱ�
{�Y)1�,6�ǒ��1���[��F�;?�ۨc@ȅia��"L`
!aC��_�/��d|#�7�Aj�2	zpu�!�K��i���Z��JT�\_��>/�u��Eu'	!�L�+�=&�
�SG��
��̩ʜ��'SOW[0�|嘇.fM�*D��#2������{+v�*L9�I��2Q���[@�A=Pb�Wo�޻]��>8�h��i�a��D�������h�{p�j����^��>��rt�*r8V�C[1���YX�5��m ���=f,�d'u@k�����˗.�I���I�
��Y��;��v��Ϭ�NuQ�>�����6|v��>S��	�0�?��NyNQ�?��:	�[oi6&g��N;�Fl�u��r�EG&م@�kZ�T�P<W��r���& �VuPw���l^��YA�O��/`#�>p��^���aW�n���9GɎ}M�,��,9�	�yE;�Q8%4Z�/�A4��@��Bb�x/ѯ�qG?JV���40���8��]8��0<��yQ���@t�.v��P�۴��C�t6��`@�N{bz*q=�F:��6���E���(�B$A$������j�d�-n;��5����L^�8�ǍARw�$J)g�5�T&��*�k����p���	���t2��&	�n��	�2]����  ų �㐯D	��*����(������Z��Sd^�B�ظp����W�J���i�2�z�Q�}�����C��|�<����4�,湤�Gjݶ�J"L~>�LǓ	�Re��t�?�
��o��#�y��]����i2]�,@BM��%�I`�1��X֥;/o<(+G5��ꇓē?�B���#�8�a�7�᤹Z�����"����[َ>��������|�W��_s2���P�%��J̀���'�Cl�*{�k��")��v~�d�gw$��f�c���go2�;���=��ғ�iB�(��u^��AW�Kr���ڄ%:���
��T_�H]��6���V��yn)�ۊ1��2,�d6�\ȼ�w�(��V�J�
��^�x�e�jz~е����(6^���T-\��:��<?[~L;m�p}[ ����2���1�*c񈮺rRМH'P�5y�T�p�䋼�uX���>^#k������Z9$3�4Wz�������WPd_�lb�M��f�	U)������Q����3��y�A�	G�|V?G��X,�N{���>��V�+pL��G�,�k�9D��`�#�W,��I�#�Q0���Դ�/)1��ӧOE�}]@#Sb-��hQ&u�w��x�ޮQ7i�O�����;���ѕ�K���JQo*�7��Q*��!�4�<�.N芨b�&�Rk�[iu�Z���Z��m4c:H�є[ �\��M�ԃ@�d(a�Q#9�!Cˈp�C��&$����2���7��Nۻ'�G{���$P�.�Q�!�0����z�5to<��?�h���b� <��!.L�`�j��x�J�[h�.� .��G/|�4�� }����Ϊ�$�}�ܒ��>c�*�ƑpߝVʟ�����\���iW?�BCXа//B̐��]�,΀�p})�ۈv�~�<V���ZQ��> ݼ��-�3�tX<�����/��%�8%5�~4x��IX��(4�|D# j<�L��9%����'#eL��,�1�,���hb��)k�H&>3(��<.G{�.�]d^?[���Ϻ�[F�L(��e���G)���R��NAs�M�w9�fcorf��Q���ڐ'M�շ����#�
���T�0EP$�%��R�����j���w%�������*��
���a�����7�
��,h��3d֏��̡L�/F�;GW+IZ65B1�'����E�e�f6�W_�����B����@6,eˍ�I�>��<*�9p��t��z+�v�*"�ِ�8s����{7/�>�ٖs��Y�\�� ���� �>�	�R8�e�
��	Lj1����LB�`�p��
���͓/ogX�(��|��E���{�T��дP:��0:�Y������Wӏ���A?=����+��o��R�M�5�@�/xetf3��x㝮6��1���Uk|�՜���ÙKz���9UXiŢ�ٗ�%3�2��U������w�XJn��wx���6¹�^��c2�#�>�$~e^[8)NHS���.�p��s[�0�7�&�W���~k���:�ke�d�2�OΕC���W����ɐ�-���D�F�蓒�UZ�y�2�H��'����O�o���\F����ym���������Re��['���v8	���۔�cI��QPYB9#U}HXoAY�h�ԪA�'�݁�v��ځ+*�]�����a;�e�ɊW*Tc���@�8T���%���a��n�g1:��ӿ��L��ϙe�EI�Iz?��1u�[}6��X/{�~��~dh l����.���|��_k}�������c�����X;mE�zӵn�K��[��$��\�k���fヰߍ)�$Ʉ%���:	b��pY<j3'��}+ɯ���/D�$d5�HR>&u֕9{`Lj���%=C�Jl"G�{���E�!�,_V|�l[��BU��@�ʪ$���%mxy]y�8�=�`�X_r+�8cu��`Vxe9}`G#�l�,S�]GWKt]��ql\Ds$)��p�	�\0�~	�S��r�|��"Lik�M*��6iw/���F��{�{��?#rB��+����5��7���S��L(�d��CB�A��j�`�P��ϱ2��R�Q;���2UډxjAc9@�lY|:Ľ_�3�[���J�}LaM!̞?��8
az v����O
�b<�H��%��8�����nd��Ӯ.�[��9ic�V�`7k�V�-7l̖���ڍ����0sF���mlt"]٫��1o����)�i~G��+������8�/��0cDhN"C�ϊ���Έ�l�"W$1!�`ۙ^/9C��Lh�Jfҝ����&��Pk:��U@]�����H�=I�b��++/����]��|�T1�	�����?9�R�,�{/��~xM�b���Q<_1�1HMr�ߏ�Xte�SZ�g�t˘`���X�H��4Wl�n�u�o�vi�F� X�8���,���;���s��}X�������/�aʰ�i+�7�s
$Vλ��^x���f]p8�ۿK7pY(��XJ��e���S��go.�PavO��q�a�8j�zH���K��/P���~Cm�<}�3�N/��`Ss}KD�Ԣ?�),�J���hY�	ܑ�9��+��u��`|�R�i��* v�I�L]�KtF�M�2O�_�vw_������^�� �� p<��Z�9�ؿ��
�u�a)�7�X��ƍy$��E;��h8n�1��cD�#q��ՁV��G�C";r�Z+��f)��s���"��j�����ԫ�CT�v��J�_�q��J�O�0a�Ȧ��d~��
���t2N���W���:��ݹ����L*ʎ��������g�����7����o��\���Dq��>�(Β�A|5#oU���mâ�z]c���Ջ�և{s��n�*\[��1d��Q�;�h�qA��P��X=ߦ�Y[Z��s��b<��Y�����:9�y��H�b`����^�G�|��t+Ĝ�)*����m>�g��3��Y��h� ���$Bkw�vC,��B�Z�5e$VRyP�����h6E����n7:����W��W�G�l\�+��J5��$	��kQDRa�/��r����k�<��9�?�6�5'_����t����ߺ��y���1�������3}I Γ�:1��Z�p�u\~��<B��5��i��8��֧`�m���
Y=S\aZ��v�4��7ݽ��]��4ّ}�6��mç=�dF��9�[>��L����WH�5o�^�k�lOZ�`��>=���߇1�
��_Ҕ9�Oh,�h�����oO�O`Y~�_!�WPL$�׽ݓ���ɩ�8�';�Q8��fAuv9�S�&5��6�g�q�,n�P�rxo��@�Nv[�1�$�1�����ͧ|�f`Jn��h���ƅ��Xp6���3��ڢF�h��Y6�ó'�'[���-�m3k�yE ����{R�W뾗1��KӎI��3(��[��b�͍V�^��	���-����U4};��q�y8	�/	梖��L�~81�])�UM?9����Vb����T�9�w� _>����w�D
1 }mrY��;�[X%�����<��?��)���t��#��3����la
3�jq�/������i��J�>�j��H�!1����n:��$�I�ڪ�7�@���fs��W=�8ߢ�ɧa�;��:0��~K{j�8n�s�3�*��w�`��J�i�!��)��{"U����n�P��IX�T�0��$�@J(e%�Ҕ���O�#F=��'" \��9����$�@�ҽ��Q}��n����>��9k��j��Y��~
��	��ʞ���D�VW�u��H�/��9��@W�"�=����q�I=7n�A��Q�2�I yDT�ɦ֦�UR�6F<���1��ࣔ��� y�דT�J�G���T4nH�M+�aԻ�0ź�$=�X"&��TB���J9W<�V� ƄZ�>�t���Cͼ�G�*�岚6��Ӈ�r~ur&
�ݻ'&0��v�M���n{w���}��Zl��!�p���E;`��`������|j�퉵�ZM|^焝�4�=�8-�Ňz����߻�����J�|}��]�� ��
��g	�c���'M`כV1�O�(� M�J�����%�'n���UXc���l��ZQ+E������3�Ŋ�;����R/�j/�j�X#T�s��0�S�2��ʯ�{���ŭ�'�����0S��&�Ԩ%��'��Z��zh	'x?���U�Y3S�P�u:��1=����тi�A'q���g����" m+q�ke;�V�m��g,<���^��wN���UG��l���5	���f�%K���%y�ZR���PR(;6:�}9O�]7w���%^~Ԇ�8��x������2a�,�ם�vI�HD�'J����)ێ�Ѭ�B!A�(j��?��%�B�4�hf�E��)X���I�M����y<�"w��x��:��iؗ08B���7�\�8N�apU���M�Oe����	QQ�6"��s��O^�M�����s�,�v]����E]4/��I�_�.�x.����N������Dj\�ְ �J
���E�zo�Վ> ����\a�W�+x(����Wű��T��5Y��5V� ��j�F����j6�e#�P?(ͮ��Q&u��4WO�$�,p���,u LX�nq�\8?��ė[�-˯�,�i6�!�#i�cڕ̧,�Z�r�9A���0��(���bA������T1����������d��݈-����(^º���R�R~d�a]������5��5���W�w��i�V|]�O��i��?�{��{����?�V 2���t�X�>��C��`<A�N���x<�oT1%Փ�����j�.�g�Љ��Ƽ�O�q���~�<�j��W6K��_&zJ�*	���,�Gq���/	��%�������%&����B�Ե���N
e?�<�4���x��D��
�<�A҆�p�B�6)�j5���B�A�c
�������u �������,Vꦵ���ӻ�Q۵���i�������������QL�j�*��HYT�k;ƀP%M��M�=��1̣�X�4����U�\+�Wc#r(]%��\�)-��Y��%Mu�t�x������ � $'�N�m��d�P��˘Q7Ӊ�.����s\�p�*��LЗd�\��-��.*d��0$�����r�4qTQ�k�I��	c�!us J�n��۾���u0��2o�qq$�2D�T@���V��xh���Vd�9,�}�)��OWv�G��N'!.�)�v�*0��Z��� ��x��A�#-2R �4B��ye*��m�È�$�J��:E�掗Ktrn�[����E"�!���dv�<S��Z<O�{��>�L��ڝ9b�!�{��y�=,�󲶞�-|��djw��C8Yֵ��,P-w�lD��
.�x��0¢P6�J:�Ɲ�a����i� ����*'�E��QN*��u�=�i����N��t��al���TV �;.�n�CR�NUdK�C��=��B?���K$!0��D��U;�?�ǻ���F� 䥝�BD�ӥ���m�=��NjY���X���	mW
�v~��ߺ�"=��E�<|G�������̴�1,�[�NI��1��}e�͵�91Q~l��;��{jȧ��R��S���z��ʭa��RH�j��]�ă� ����;ך|��Z��.���}��ٛ���B�K�'p:��o��Ӵ��mm8�~���s�M����,�O�x,S��K`�<��(7DyK��d��qw����)��N/��Ig�X�(2���r6���l���i0"�Rr0FGa�y�-���G�@_��[jB�Tl��u�6Ðvv�U��[&դ��!r/1��|���.@��ŀdr@�`�[P�%��-��\o_$1�+�Q��^ITr�T3p��fq�v�` �d�R�fZ��:�S�g�w`M��"��� ���fzO1�̢�0�g��o��̩��=ya�����ELzkqy#�h/t'X��4������9�ݍ�f�E�t��"!#�c�K+t�»\~Q�e���6o�����h�>(�	!�/%p^!H�u0��6M�;��+OBؗ!�$%���+���ό��:%�[��"�Ǣ��BNÇ�F����4v���se1��0���0	z��
��)����!�+:9��T���q�Y@����f^I\AU��.��1�Lf
�� �z)��,�5|Wx�������*��un=����
��k]!XYmq��[+�Q� �������c�P�2N��b����II�+���H\죀2)Pj:�"A�p��vv��q���w��)�;�����x
W�Z��{޿������H���{-L���W������z����񿾒��
+������W0 �F�,�}ܾ���Pɀ
G�H=�%^G��ꉚ<W�3Q_����uZ"�EQ�W��5�<<�0���0�N8��ϊfټ^S�}`R)W\�Q����]}@)Ս�	�eM$�CUn6E�++i���`;3�_k'���NH�s�|�{���C���Pj���i
%^&������=|�bd�­X�?�ġ�!�l��1�*�F��	��</�(��]I�6�O��M��?�1R�Fͭ���D�S�\����`7#�q�����T*(���K@�j�[��2d���ɿ��g�������.�q�#'�%1�>C%9I��!;�f�a�܂23e���y��He�E8���)����Üf�_H�2J�_(��3���t��' �kJ4ot� !	��(�,�&@�Cʎ�Mѯv�z7�����A�D��A"���S���2cJ�;~pO�Ө���Hh=Y�d~����
���$l���R#�	
��+ֈ��6
�(A�6�
sur[gԔ	�2,Rb�QMH9�� ���ֹg�
az�����5�ݎe�Q�$���(B�.J�<����هU$�OX��!��e�F�ѪĿ����XŞ��I�Y�8Dq��Ā�AO��8�AM���.���#��6OT:$���$"zE4��(�������:ғ� 