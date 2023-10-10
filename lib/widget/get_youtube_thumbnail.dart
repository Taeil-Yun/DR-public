String getYoutubeThumbnail(String youtubeURL) {
  String uri = youtubeURL.startsWith('https://youtu.be/')
    ? youtubeURL.split('https://youtu.be/')[1]
    : youtubeURL.startsWith('https://youtube.com/shorts/') || youtubeURL.startsWith('https://www.youtube.com/shorts/')
      ? youtubeURL.split('shorts/')[1].contains('?') ? youtubeURL.split('shorts/')[1].split('?')[0] : youtubeURL.split('shorts/')[1]
      : youtubeURL.split('watch?v=')[1];

  return 'https://img.youtube.com/vi/$uri/0.jpg';
}