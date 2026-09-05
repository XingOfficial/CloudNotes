package com.notesapp.api

import java.net.InetAddress
import java.net.UnknownHostException
import okhttp3.Dns
import okhttp3.OkHttpClient
import okhttp3.Request

class CustomDns : Dns {
    private val dnsClient: OkHttpClient = OkHttpClient.Builder()
        .dns(Dns.SYSTEM)
        .build()

    override fun lookup(hostname: String): List<InetAddress> {
        try {
            return Dns.SYSTEM.lookup(hostname)
        } catch (e: UnknownHostException) {
            // 系统 DNS 失败，尝试 DoH
        }

        try {
            val url = String.format(DOH_URL, hostname)
            val request = Request.Builder()
                .url(url)
                .header("accept", "application/dns-json")
                .build()
            dnsClient.newCall(request).execute().use { response ->
                if (response.isSuccessful && response.body != null) {
                    val body = response.body!!.string()
                    val addresses = parseDoHResponse(body, hostname)
                    if (addresses.isNotEmpty()) {
                        return addresses
                    }
                }
            }
        } catch (e: Exception) {
            // DoH 也失败
        }

        throw UnknownHostException("无法解析域名 $hostname，请检查网络连接或切换网络后重试")
    }

    private fun parseDoHResponse(json: String, hostname: String): List<InetAddress> {
        val result = mutableListOf<InetAddress>()
        try {
            val obj = org.json.JSONObject(json)
            val answers = obj.optJSONArray("Answer")
            if (answers != null) {
                for (i in 0 until answers.length()) {
                    val answer = answers.getJSONObject(i)
                    val type = answer.optInt("type", 0)
                    if (type == 1) {
                        val ip = answer.optString("data", "")
                        if (ip.isNotEmpty()) {
                            result.add(InetAddress.getByName(ip))
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // 解析失败
        }
        return result
    }

    companion object {
        private const val DOH_URL = "https://cloudflare-dns.com/dns-query?name=%s&type=A"
    }
}
