#increment the build number in our plist
buildPlist=${INFOPLIST_FILE}

#pull the current values from our application's plist
bundleVersionShort=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $buildPlist)
buildNumber=$(/usr/libexec/PlistBuddy -c "Print SnibbeBuildNumber" $buildPlist)
echo "Existing build number: $buildNumber"

#increment the build number
buildNumber=$(($buildNumber + 1))
echo "Incrementing build number to $buildNumber"

#store the newly incremented build number
/usr/libexec/PlistBuddy -c "Set :SnibbeBuildNumber $buildNumber" $buildPlist

#create the full bundle version string by appending the build number to the short bundle string

newBundleVersionShort=$bundleVersionShort.$buildNumber
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $newBundleVersionShort" $buildPlist
echo "Setting the bundle version (short) to $newBundleVersionShort"