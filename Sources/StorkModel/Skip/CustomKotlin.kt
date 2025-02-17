package stork.model

import android.content.Context
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import skip.lib.*
import skip.foundation.*
import java.util.Locale
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resumeWithException

/// An example of using custom Kotlin to perform a location lookup. See Location.swift
suspend fun fetchCurrentLocation(context: Context): Pair<Double, Double> = withContext(Dispatchers.IO) {
    suspendCancellableCoroutine<Pair<Double, Double>> { continuation ->
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                val latitude = location.latitude
                val longitude = location.longitude
                locationManager.removeUpdates(this)
                continuation.resume(Pair(latitude, longitude))
            }

            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }

        locationManager.requestSingleUpdate(LocationManager.GPS_PROVIDER, locationListener, Looper.getMainLooper())

        continuation.invokeOnCancellation {
            locationManager.removeUpdates(locationListener)
            continuation.cancel()
        }
    }
}

/// Fetches the city and state for a given latitude and longitude.
/// Fetches the city and state (state abbreviation) for a given latitude and longitude.
suspend fun fetchCityAndState(context: Context, latitude: Double, longitude: Double): Pair<String?, String?> = withContext(Dispatchers.IO) {
    val stateAbbreviations = mapOf(
        "Alabama" to "AL", "Alaska" to "AK", "Arizona" to "AZ", "Arkansas" to "AR", "California" to "CA",
        "Colorado" to "CO", "Connecticut" to "CT", "Delaware" to "DE", "Florida" to "FL", "Georgia" to "GA",
        "Hawaii" to "HI", "Idaho" to "ID", "Illinois" to "IL", "Indiana" to "IN", "Iowa" to "IA",
        "Kansas" to "KS", "Kentucky" to "KY", "Louisiana" to "LA", "Maine" to "ME", "Maryland" to "MD",
        "Massachusetts" to "MA", "Michigan" to "MI", "Minnesota" to "MN", "Mississippi" to "MS",
        "Missouri" to "MO", "Montana" to "MT", "Nebraska" to "NE", "Nevada" to "NV", "New Hampshire" to "NH",
        "New Jersey" to "NJ", "New Mexico" to "NM", "New York" to "NY", "North Carolina" to "NC",
        "North Dakota" to "ND", "Ohio" to "OH", "Oklahoma" to "OK", "Oregon" to "OR", "Pennsylvania" to "PA",
        "Rhode Island" to "RI", "South Carolina" to "SC", "South Dakota" to "SD", "Tennessee" to "TN",
        "Texas" to "TX", "Utah" to "UT", "Vermont" to "VT", "Virginia" to "VA", "Washington" to "WA",
        "West Virginia" to "WV", "Wisconsin" to "WI", "Wyoming" to "WY"
    )

    val geocoder = Geocoder(context, Locale.getDefault())
    try {
        val addresses = geocoder.getFromLocation(latitude, longitude, 1)
        if (addresses.isNullOrEmpty()) {
            return@withContext Pair(null, null)
        }
        val address = addresses[0]
        val city = address.locality // The city name
        val stateFullName = address.adminArea // Full state name
        val stateAbbreviation = stateFullName?.let { stateAbbreviations[it] } // Lookup abbreviation
        
        Pair(city, stateAbbreviation)
    } catch (e: Exception) {
        // Handle geocoding errors, e.g., network issues
        Pair(null, null)
    }
}

suspend fun geocodeAddress(context: Context, address: String): Pair<Double, Double> {
    return suspendCancellableCoroutine { continuation ->
        try {
            val geocoder = Geocoder(context, Locale.getDefault())
            val results = geocoder.getFromLocationName(address, 1)
            if (results.isNullOrEmpty()) {
                continuation.resumeWithException(Exception("Address not found"))
            } else {
                val location = results[0]
                continuation.resume(Pair(location.latitude, location.longitude))
            }
        } catch (exception: Exception) {
            continuation.resumeWithException(exception)
        }
    }
}

