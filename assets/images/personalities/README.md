# Personality Profile Pictures

Add your custom personality profile pictures to this directory with the following file names:

## Required Image Files:

1. **robot.png** - For the default robot assistant
2. **shrek.png** - For Shrek personality
3. **harry_potter.png** - For Harry Potter personality
4. **minions.png** - For Minions personality
5. **trex.png** - For T-Rex/Jurassic Park personality
6. **homer_simpson.png** - For Homer Simpson personality

## Image Specifications:

- **Format**: PNG preferred (also supports JPG/JPEG)
- **Size**: 512x512 pixels recommended (minimum 256x256)
- **Shape**: Square images work best (will be displayed in circular frames)
- **Background**: Transparent or solid background both work well

## Tips:

- Images should be clear and recognizable when displayed small (32px-40px)
- High contrast images work better for visibility
- Consider the character's most recognizable features
- The app will automatically fall back to emoji icons if images fail to load

## How to Add Images:

1. Find or create your character images
2. Resize them to 512x512 pixels
3. Save them with the exact file names listed above
4. Place them in this `assets/images/personalities/` directory
5. Run `flutter pub get` and restart the app to see your custom images!

Your personality selection dialog and chat interface will automatically use these custom images instead of the default emoji characters. 