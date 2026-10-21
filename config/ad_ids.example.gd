# Reference examples only: this script is NOT read by AdsConfig or the native exporter.
# Configure the documented ProjectSettings keys in an isolated production workspace.
# AdMob identifiers are public routing identifiers, not signing secrets; repository policy
# still keeps real account configuration out of Git. Never put signing credentials here.
# Development uses the official test IDs below. See docs/android-integrations.md.

extends Node

const ADMOB_APP_ID_ANDROID: String = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
const ADMOB_APP_ID_IOS: String = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"

# AdMob test IDs — safe for development builds
const REWARDED_ANDROID: String = "ca-app-pub-3940256099942544/5224354917"
const REWARDED_IOS: String = "ca-app-pub-3940256099942544/1712485313"
const INTERSTITIAL_ANDROID: String = "ca-app-pub-3940256099942544/1033173712"
const INTERSTITIAL_IOS: String = "ca-app-pub-3940256099942544/4411468910"
