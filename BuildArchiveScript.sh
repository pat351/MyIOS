project_dir=`pwd`
project_name='helloworld'
keychain="login"
keychain_password=""
certfile="/Users/nanhap/Desktop/helloworld/KTH_Enterpise_certification.p12"
certfile_passwd="ok!@#$"
provisioning_profile="iPhone Distribution: KT Hitel Co., Ltd."
mobileprovision="/Users/nanhap/Desktop/helloworld/helloworld.mobileprovision"
mobileprovision_system_dir="/Users/nanhap/Library/MobileDevice/Provisioning Profiles/"

function failed() {
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}
function validate_keychain() {
  # unlock the keychain containing the provisioning profile's private key and set it as the default keychain
  security unlock-keychain -p "$keychain_password" "$HOME/Library/Keychains/$keychain.keychain"
  #security default-keychain -s "$HOME/Library/Keychains/$keychain.keychain"
 
  # import key
  echo "Import certficate key"
  security import "$certfile" -P "$certfile_passwd" -k "$HOME/Library/Keychains/$keychain.keychain"

  echo "Copy MobileDevice Provisioning Profiles Directory"
  cp "$mobileprovision" "$mobileprovision_system_dir/"

  # describe the available provisioning profiles
  echo "Available provisioning profiles"
  security find-identity -p codesigning -v

  #verify that the requested provisioning profile can be found
  (security find-certificate -a -c "$provisioning_profile" -Z | grep ^SHA-1) || failed provisioning_profile  
}

function build_app() {
  xcrun -sdk iphoneos xcodebuild CODE_SIGN_IDENTITY="$provisioning_profile" > xcodebuild_output
  if [ $? -ne 0 ]
  then
    tail -n20 xcodebuild_output
  fi
}

function sign_app() {
  [ -d $project_dir/archive ] || mkdir -p $project_dir/archive
  xcrun -sdk iphoneos PackageApplication build/Release-iphoneos/"$project_name".app -o "$project_dir/archive/$project_name.ipa" --sign "$provisioning_profile" --embed "$mobileprovision"
}


echo "**** Validate Keychain"
validate_keychain
echo

echo "**** Build"
build_app
echo

echo "**** Package Application"
sign_app
echo
