import 'package:audio_service/audio_service.dart';

import 'package:get_it/get_it.dart';
import 'auth_service.dart';

import '../page_manager.dart';
import 'audio_handler.dart';
import 'playlist_repository.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  print('[ServiceLocator] Setting up service locator...');
  
  // services
  final handler = await initAudioService();
  print('[ServiceLocator] Handler runtimeType: ${handler.runtimeType}');
  getIt.registerSingleton<AudioHandler>(handler);
  //getIt.registerSingleton<AudioHandler>(await initAudioService());
  getIt.registerLazySingleton<PlaylistRepository>(() => DemoPlaylist());

  // page state
  getIt.registerLazySingleton<PageManager>(() => PageManager());
  getIt.registerLazySingleton<AuthService>(() => AuthService());

}
