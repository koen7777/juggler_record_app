# reset_flutter_web.ps1
# Flutter Web Reset Script

Write-Host "Flutter Web reset start..."

# Delete build cache
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\.dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\pubspec.lock -ErrorAction SilentlyContinue

# Get Flutter dependencies
flutter pub get

# Run Flutter Web
flutter run -d chrome

Write-Host "Flutter Web reset complete!"
