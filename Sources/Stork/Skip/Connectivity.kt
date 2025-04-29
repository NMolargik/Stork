package stork.module

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

/** Returns true when the device currently has an active network that provides internet. */
fun isNetworkConnected(context: Context): Boolean {
	val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
	val network = cm.activeNetwork ?: return false
	val caps = cm.getNetworkCapabilities(network) ?: return false
	return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
}

// Obtain an Application Context when none is provided (called from Swift)
@Suppress("PrivateApi", "DiscouragedPrivateApi")
private fun appContext(): Context {
	val activityThread = Class.forName("android.app.ActivityThread")
	val currentAppMethod = activityThread.getMethod("currentApplication")
	val application = currentAppMethod.invoke(null) as android.app.Application
	return application.applicationContext
}

/** Convenience no‑arg overload so Swift can simply call ConnectivityKt.isNetworkConnected() */
fun isNetworkConnected(): Boolean = isNetworkConnected(appContext())

/** Compose helper if you ever need the value on the Compose side. */
@Composable
fun rememberIsNetworkConnected(): Boolean =
	isNetworkConnected(LocalContext.current)
