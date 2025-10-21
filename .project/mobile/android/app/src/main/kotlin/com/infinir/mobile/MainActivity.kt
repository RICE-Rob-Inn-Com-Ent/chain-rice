package com.infinir.mobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { InfiniRTheme { HomeScreen() } }
    }
}

@Composable
fun InfiniRTheme(content: @Composable () -> Unit) {
    MaterialTheme(content = content)
}

@Composable
fun HomeScreen() {
    val gradient =
            Brush.linearGradient(
                    colors =
                            listOf(
                                    Color(0xFF581C87), // purple-900
                                    Color(0xFF1E3A8A), // blue-900
                                    Color(0xFF000000) // black
                            )
            )

    val textGradient =
            Brush.linearGradient(
                    colors =
                            listOf(
                                    Color(0xFFC084FC), // purple-400
                                    Color(0xFFEC4899), // pink-500
                                    Color(0xFF3B82F6) // blue-500
                            )
            )

    Box(
            modifier = Modifier.fillMaxSize().background(gradient),
            contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                    text = "InfiniR",
                    fontSize = 80.sp,
                    fontWeight = FontWeight.Bold,
                    style = MaterialTheme.typography.displayLarge.copy(brush = textGradient)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                    text = "Infinite Reality Awaits",
                    fontSize = 20.sp,
                    color = Color(0xFFD1D5DB) // gray-300
            )
        }
    }
}
