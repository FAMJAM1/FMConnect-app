package com.hiddify.hiddify

import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.hiddify.core.api.v2.hcommon.Empty
import com.hiddify.core.api.v2.hcore.CoreClient
import com.hiddify.core.api.v2.hcore.OutboundGroup
import com.hiddify.core.api.v2.hcore.SelectOutboundRequest
import com.hiddify.hiddify.utils.GrpcClientProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// standalone dialog activity for the notification's "Switch" action - no
// MainActivity/Flutter engine involved, just a native picker
class QuickSwitchActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "A/QuickSwitch"
        private const val SELECT_GROUP_TAG = "select"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        applyNightModeFromPreference()
        super.onCreate(savedInstanceState)
        loadAndShowPicker()
    }

    // theme preference is stored under the "flutter." prefix by the Dart side
    private fun applyNightModeFromPreference() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val mode = when (prefs.getString("flutter.theme_mode", "system")) {
            "light" -> AppCompatDelegate.MODE_NIGHT_NO
            "dark", "black", "console" -> AppCompatDelegate.MODE_NIGHT_YES
            else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
        }
        AppCompatDelegate.setDefaultNightMode(mode)
    }

    private fun loadAndShowPicker() {
        GlobalScope.launch(Dispatchers.IO) {
            val group = try {
                val coreClient = GrpcClientProvider.grpcClient.create(CoreClient::class)
                // (MainOutboundsInfo() only returns the selected item, not the full list)
                val (send, receive) = coreClient.OutboundsInfo().executeIn(this)
                send.send(Empty())
                send.close()
                val groups = receive.receive()
                receive.cancel()
                groups.items.find { it.tag == SELECT_GROUP_TAG }
            } catch (e: Exception) {
                Log.e(TAG, "failed to fetch outbound groups", e)
                null
            }
            withContext(Dispatchers.Main) {
                if (isFinishing) return@withContext
                val visibleItems = group?.items?.filter { it.is_visible } ?: emptyList()
                if (visibleItems.isEmpty()) {
                    Toast.makeText(this@QuickSwitchActivity, R.string.switch_server_unavailable, Toast.LENGTH_SHORT).show()
                    finish()
                    return@withContext
                }
                showPicker(group!!, visibleItems)
            }
        }
    }

    private fun showPicker(group: OutboundGroup, items: List<com.hiddify.core.api.v2.hcore.OutboundInfo>) {
        val tags = items.map { it.tag }
        val labels = items.map { it.tag_display.ifBlank { it.tag } }.toTypedArray()
        val selectedIndex = tags.indexOf(group.selected)

        var pickedTag: String? = null
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.switch_server)
            .setSingleChoiceItems(labels, selectedIndex) { dialog, which ->
                pickedTag = tags[which]
                dialog.dismiss()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .setOnDismissListener {
                pickedTag?.let { selectOutbound(it) }
                finish()
            }
            .show()
    }

    private fun selectOutbound(tag: String) {
        GlobalScope.launch(Dispatchers.IO) {
            try {
                val coreClient = GrpcClientProvider.grpcClient.create(CoreClient::class)
                coreClient.SelectOutbound()
                    .executeBlocking(SelectOutboundRequest(group_tag = SELECT_GROUP_TAG, outbound_tag = tag))
                withContext(Dispatchers.Main) {
                    Toast.makeText(
                        this@QuickSwitchActivity,
                        getString(R.string.server_switched, tag),
                        Toast.LENGTH_SHORT,
                    ).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "failed to select outbound", e)
            }
        }
    }
}
