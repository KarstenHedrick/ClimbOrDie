# 🎵 Lobby Music Setup Guide

This guide will help you set up and customize lobby music for your Roblox game.

## 📁 Files Created

1. **`ServerScriptService/Services/MusicService`** - Server-side music management
2. **`StarterPlayer/StarterPlayerScripts/MusicClientScript`** - Client-side music playback
3. **`ReplicatedStorage/MusicConfig`** - Music configuration file
4. **`MUSIC_SETUP_GUIDE.md`** - This guide

## 🎶 How It Works

The music system automatically:
- Plays lobby music when players are in the lobby
- Switches to game music when a game starts
- Returns to lobby music when the game ends
- Handles player joining/leaving seamlessly
- Includes smooth fade transitions between music

## ⚙️ Customizing Your Music

### Step 1: Upload Your Music
1. Go to the **Create** section on Roblox
2. Click **Audio** → **Upload Audio**
3. Upload your music file (MP3, WAV, etc.)
4. Copy the **Asset ID** from the URL

### Step 2: Configure Music Settings
Edit the `ReplicatedStorage/MusicConfig` file:

```lua
local MusicConfig = {
    lobbyMusic = {
        soundId = "rbxassetid://YOUR_LOBBY_MUSIC_ID_HERE", -- Replace with your asset ID
        volume = 0.5,  -- Volume level (0.0 to 1.0)
        looped = true, -- Whether music should loop
        playbackSpeed = 1.0 -- Playback speed
    },
    
    gameMusic = {
        soundId = "rbxassetid://YOUR_GAME_MUSIC_ID_HERE", -- Replace with your asset ID
        volume = 0.3,  -- Usually lower than lobby music
        looped = true,
        playbackSpeed = 1.0
    }
}
```

### Step 3: Example Configurations

#### Energetic Lobby + Intense Game Music
```lua
MusicConfig.lobbyMusic = {
    soundId = "rbxassetid://1234567890", -- Upbeat lobby music
    volume = 0.6,
    looped = true,
    playbackSpeed = 1.0
}

MusicConfig.gameMusic = {
    soundId = "rbxassetid://0987654321", -- Intense game music
    volume = 0.4,
    looped = true,
    playbackSpeed = 1.0
}
```

#### Calm Lobby + Action Game Music
```lua
MusicConfig.lobbyMusic = {
    soundId = "rbxassetid://1111111111", -- Calm/ambient music
    volume = 0.4,
    looped = true,
    playbackSpeed = 1.0
}

MusicConfig.gameMusic = {
    soundId = "rbxassetid://2222222222", -- Action music
    volume = 0.5,
    looped = true,
    playbackSpeed = 1.0
}
```

## 🎛️ Advanced Features

### Volume Control
- **Lobby Music**: Usually 0.4-0.6 (background music)
- **Game Music**: Usually 0.3-0.5 (shouldn't interfere with gameplay)

### Playback Speed
- `1.0` = Normal speed
- `0.5` = Half speed
- `1.5` = 1.5x speed

### Looping
- `true` = Music repeats continuously
- `false` = Music plays once and stops

## 🔧 Troubleshooting

### Music Not Playing?
1. Check that your Asset ID is correct
2. Ensure the audio file is approved by Roblox
3. Verify the file path in MusicConfig is correct

### Music Too Loud/Quiet?
1. Adjust the `volume` setting in MusicConfig
2. Test with different volume levels (0.1 to 1.0)

### Music Not Looping?
1. Make sure `looped = true` in your configuration
2. Check that your audio file is long enough

## 🎵 Music Recommendations

### Lobby Music Ideas:
- Upbeat, energetic tracks
- Calm, ambient music
- Lo-fi or chill beats
- Upbeat electronic music

### Game Music Ideas:
- Intense, action-packed tracks
- Fast-paced electronic music
- Epic orchestral music
- Rock or metal tracks

## 📝 Notes

- The system automatically handles music transitions
- New players joining will hear the current music
- Music stops when players leave the game
- All music includes smooth fade in/out effects
- The system is integrated with your existing game flow

## 🚀 Ready to Use!

Your lobby music system is now ready! The music will automatically:
- Start playing when the server starts
- Switch between lobby and game music
- Handle all player connections/disconnections
- Provide smooth transitions between music tracks

Just upload your music files and update the `MusicConfig` file with your Asset IDs! 