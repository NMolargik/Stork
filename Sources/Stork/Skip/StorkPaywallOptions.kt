// Sources/Stork/Skip/StorkPaywallOptions.kt
package stork.module          // <- matches Swift module “Stork” after Skip transpilation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import com.revenuecat.purchases.kmp.models.CustomerInfo
import com.revenuecat.purchases.kmp.models.PurchasesError
import com.revenuecat.purchases.kmp.models.Package
import com.revenuecat.purchases.kmp.models.StoreTransaction
import com.revenuecat.purchases.kmp.ui.revenuecatui.PaywallListener
import com.revenuecat.purchases.kmp.ui.revenuecatui.PaywallOptions
/**
 * Android-side Paywall listener that mirrors the callbacks you already
 * handle on iOS.
 *
 * @param onCompleted  invoked when a purchase or restore finishes successfully
 * @param setError     invoked with a user-visible message when an error occurs
 */
@Composable
fun rememberStorkPaywallOptions(
	onCompleted: () -> Unit,
	setError: (String) -> Unit,
): PaywallOptions = remember {
	PaywallOptions(dismissRequest = onCompleted) {
		listener = object : PaywallListener {

			// ── Purchase flow ────────────────────────────────────────────────
			override fun onPurchaseStarted(rcPackage: Package) {
				println("Purchases: purchase started → ${rcPackage.identifier}")
			}

			override fun onPurchaseCompleted(
				customerInfo: CustomerInfo,
				storeTransaction: StoreTransaction,
			) {
				println("Purchases: purchase completed")
				onCompleted()
			}

			override fun onPurchaseCancelled() {
				println("Purchases: purchase cancelled")
				setError("Purchase cancelled")
			}

			override fun onPurchaseError(error: PurchasesError) {
				println("Purchases: purchase error → $error")
				setError("Purchase failed—please try again")
			}

			// ── Restore flow ─────────────────────────────────────────────────
			override fun onRestoreStarted() {
				println("Purchases: restore started")
			}

			override fun onRestoreCompleted(customerInfo: CustomerInfo) {
				println("Purchases: restore completed")
				onCompleted()
			}

			override fun onRestoreError(error: PurchasesError) {
				println("Purchases: restore error → $error")
				setError("Restore failed—please try again")
			}
		}
	}
}
