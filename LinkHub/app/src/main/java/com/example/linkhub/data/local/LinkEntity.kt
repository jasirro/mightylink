package com.example.linkhub.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "links")
data class LinkEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val url: String,
    val title: String,
    val description: String,
    val imageUrl: String,
    val folderId: Int?,
    val isFavorite: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
)
