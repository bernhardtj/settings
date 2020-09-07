# .local/bin/mprint
#!/bin/bash

usage() {
    cat <<EOF
usage: $(basename "$0") [options] <filename>

options:
    -h, --help                   Show this message
    -s, --server <URL>           Optionally specify server URL
    -u, --user <username>        Optionally specify server username
    -p, --pass <password>        Optionally specify server password
    -c, --color                  Use color queue instead of black-and-white
    -q, --queue <num>            Force use of queue number <num>
    -v, --verbose                Show cURL commands as they are run
    --debugging-dry-run          Don't invoke curl, fake response data

error codes:
     1                           Invocation error
     2                           Can't connect to server
     3                           Authentication rejected by server
     4                           Print job rejected by server

The server URL, username, and password can be set either with the command line,
or the environment variables MPRINT_URL, MPRINT_USERNAME, and MPRINT_PASSWORD.
The user will prompted for any of these which are still unspecified.

Authentication details can be saved in ~/.mprint if they are acquired fully
interactively. This file is automatically read on later script runs.

The following file types are usually allowed:

Microsoft Excel          xlam, xls, xlsb, xlsm, xlsx, xltm, xltx
Microsoft PowerPoint     pot, potm, potx, ppam, pps, ppsm, ppsx, ppt, pptm, pptx
Microsoft Word           doc, docm, docx, dot, dotm, dotx, rtf, txt
PDF                      pdf
Picture Files            bmp, dib, gif, jfif, jif, jpe, jpeg, jpg, png, tif, tiff
EOF
    exit "$@"
}

m_disp() {
    printf "$@" >&2
}

m_prompt() {
    printf '%s: ' "$1" >&2 && read -r $3 $2
}

m_curl() {
    if [[ $MPRINT_DEBUG ]]; then
        m_disp "\n+ curl $*\n"
        case $MPRINT_DEBUG in
        1)
            curl "$@"
            ;;
        2)
            echo FAKE var uploadFormSubmitURL = var webPrintUID = node ENDFAKE
            ;;
        esac
    else
        curl --silent "$@"
    fi
}

MPRINT_DEFAULT_SAVEFILE="$HOME/.mprint"
MPRINT_QUEUE=2
MPRINT_FILENAME=
MPRINT_SAVEFILE=
MPRINT_DEBUG=
MPRINT_GPG_OPTIONS='
--batch --no-tty --yes --quiet --armor
--passphrase-file=/etc/machine-id
--s2k-mode 3
--s2k-count 65011712
--s2k-digest-algo SHA512
--s2k-cipher-algo AES256
'

_flag_store_to=
while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        usage 0
        ;;
    -s | --server)
        _flag_store_to=MPRINT_URL
        ;;
    -u | --user)
        _flag_store_to=MPRINT_USERNAME
        ;;
    -p | --pass)
        _flag_store_to=MPRINT_PASSWORD
        ;;
    -c | --color)
        MPRINT_QUEUE=3
        ;;
    -q | --queue)
        _flag_store_to=MPRINT_QUEUE
        ;;
    -v | --verbose)
        MPRINT_DEBUG=1
        ;;
    --debugging-dry-run)
        MPRINT_DEBUG=2
        ;;
    *)
        if [[ $_flag_store_to ]]; then
            eval "$_flag_store_to=$1"
            _flag_store_to=
        else
            if [[ -z "$MPRINT_FILENAME" ]]; then
                MPRINT_FILENAME=$1
            else
                usage 1
            fi
        fi
        ;;
    esac
    shift
done

if [[ $_flag_store_to ]]; then
    usage 1
fi

if [[ -z "$MPRINT_FILENAME" ]]; then
    usage 1
fi

if [[ -z "$MPRINT_URL$MPRINT_USERNAME$MPRINT_PASSWORD" ]]; then
    MPRINT_SAVEFILE="$MPRINT_DEFAULT_SAVEFILE"
fi

if [[ $MPRINT_SAVEFILE && -f $MPRINT_SAVEFILE ]]; then
    m_disp "INFO: Using credentials at $MPRINT_SAVEFILE.\n"
    MPRINT_URL=$(head -n1 "$MPRINT_SAVEFILE" | cut -d @ -f2)
    MPRINT_USERNAME=$(head -n1 "$MPRINT_SAVEFILE" | cut -d @ -f1)
    MPRINT_PASSWORD=$(tail -n+1 "$MPRINT_SAVEFILE" | gpg $MPRINT_GPG_OPTIONS --decrypt || rm "$MPRINT_SAVEFILE")
    MPRINT_SAVEFILE=
fi

if [[ -z "$MPRINT_URL" ]]; then
    m_prompt 'Server URL' MPRINT_URL
fi
if [[ -z "$MPRINT_USERNAME" ]]; then
    m_disp "=== Authenticating to $MPRINT_URL ===\n"
    m_prompt 'User' MPRINT_USERNAME
fi
if [[ -z "$MPRINT_PASSWORD" ]]; then
    m_prompt "Password for $MPRINT_USERNAME@$MPRINT_URL" MPRINT_PASSWORD -s && printf '\n'
fi

if [[ $MPRINT_SAVEFILE ]]; then
    m_prompt "Save details to $MPRINT_SAVEFILE? [yN]" yesno
    if [[ "$yesno" =~ [Yy] ]]; then
        printf '%s@%s\n%s\n' \
            "$MPRINT_USERNAME" "$MPRINT_URL" \
            "$(gpg $MPRINT_GPG_OPTIONS --symmetric <<<"$MPRINT_PASSWORD")" >"$MPRINT_SAVEFILE"
        chmod 600 "$MPRINT_SAVEFILE"
        m_disp "Saved.\n"
    fi
fi

m_disp 'Attempting login [        ]'

JSESSIONID=$(
    m_curl "https://$MPRINT_URL/app" --output /dev/null \
        --data 'service=direct/0/Home/$Form' \
        --data 'sp=S0' \
        --data 'Form0=$Hidden$0,$Hidden$1,inputUsername,inputPassword,$Submit$0,$PropertySelection' \
        --data '$Hidden$0=true' \
        --data '$Hidden$1=X' \
        --data '$Submit$0=Log in' \
        --data '$PropertySelection=en' \
        --data "inputUsername=$MPRINT_USERNAME" \
        --data "inputPassword=$MPRINT_PASSWORD" \
        --header "Origin: https://$MPRINT_URL" \
        --cookie-jar - |
        cut -f7 | grep node | tr -d '\n'
) && m_disp '\rAttempting login [==      ]'

test -z "$JSESSIONID" && m_disp "\rAttempting login [==fail==]\nERROR: Can't connect to print server.\n" && exit 2

m_curl "https://$MPRINT_URL/app?service=action/1/UserWebPrint/0/\$ActionLink" \
    --header "Cookie: JSESSIONID=$JSESSIONID;" \
    --header "Origin: https://$MPRINT_URL" >/dev/null && m_disp '\rAttempting login [====    ]'

m_curl "https://$MPRINT_URL/app" \
    --data 'service=direct/1/UserWebPrintSelectPrinter/$Form' \
    --data 'sp=S0' \
    --data 'Form0=$Hidden,$Hidden$0,$TextField,$Submit,$RadioGroup,$Submit$0,$Submit$1' \
    --data '$Hidden=' \
    --data '$Hidden$0=' \
    --data '$TextField=' \
    --data "\$RadioGroup=$MPRINT_QUEUE" \
    --data '$Submit$1=2. Print Options and Account Selection »' \
    --header "Cookie: JSESSIONID=$JSESSIONID;" \
    --header "Origin: https://$MPRINT_URL" >/dev/null && m_disp '\rAttempting login [======  ]'

UPLOAD=$(
    m_curl "https://$MPRINT_URL/app" \
        --data 'service=direct/1/UserWebPrintOptionsAndAccountSelection/$Form' \
        --data 'sp=S0' \
        --data 'Form0=copies,$Submit,$Submit$0' \
        --data 'copies=1' \
        --data '$Submit=3. Upload Document »' \
        --header "Cookie: JSESSIONID=$JSESSIONID;" \
        --header "Origin: https://$MPRINT_URL" |
        grep "var uploadFormSubmitURL = " | cut -d \' -f2
) && m_disp '\rAttempting login [===ok===]'

test -z "$UPLOAD" && m_disp '\rAttempting login [==fail==]\nERROR: Invalid username or password.\n' && exit 3

m_disp '\nUploading file...\n'

m_curl "https://$MPRINT_URL$UPLOAD" \
    --form "file[]=@$MPRINT_FILENAME" \
    --header "Cookie: JSESSIONID=$JSESSIONID;" >/dev/null

JOB=$(
    m_curl "https://$MPRINT_URL/app" \
        --data 'service=direct/1/UserWebPrintUpload/$Form$0' \
        --data 'sp=S1' \
        --data 'Form1=' \
        --header "Cookie: JSESSIONID=$JSESSIONID;" \
        --header "Origin: https://$MPRINT_URL" | grep 'var webPrintUID =' | cut -d \' -f2
)

test -z "$JOB" && m_disp 'ERROR: Job not accepted by server.\n' && exit 4

m_curl -s "https://$MPRINT_URL/rpc/web-print/job-status/$JOB.json" | python -m json.tool
