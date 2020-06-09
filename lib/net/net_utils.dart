import 'dart:io';

import 'package:bujuan/api/netease_cloud_music.dart';
import 'package:bujuan/entity/login_entity.dart';
import 'package:bujuan/entity/sheet_details_entity.dart';
import 'package:bujuan/entity/today_song_entity.dart';
import 'package:bujuan/utils/bujuan_util.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class NetUtils {
  static final NetUtils _netUtils = NetUtils._internal(); //1
  factory NetUtils() {
    return _netUtils;
  }
  NetUtils._internal();

  Future<Map> _doHandler(String url, [Map param = const {}]) async {
    var answer = await cloudMusicApi(url, parameter: param, cookie: await BuJuanUtil.getCookie());
    var map;
    if (answer.status == 200) {
      if (answer.cookie != null && answer.cookie.length > 0) {
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;
        CookieJar cookie = new PersistCookieJar(dir: tempPath, ignoreExpires: true);
        cookie.saveFromResponse(Uri.parse("https://music.163.com/weapi/"), answer.cookie);
      }
      map = answer.body;
    }
    return map;
  }

  //手机号登录
  Future<LoginEntity> loginByPhone(String phone, String password) async {
    var login;
    var map = await _doHandler("/login/cellphone", {"phone": phone, "password": password});
    if(map!=null){
      login = LoginEntity.fromJson(map);
    }
    return login;
  }

  //获取歌单详情
  Future<SheetDetailsEntity> getPlayListDetails(id) async{
    SheetDetailsEntity sheetDetails;
    var map = await _doHandler('/playlist/detail',{'id':id});
    if(map!=null) sheetDetails = SheetDetailsEntity.fromJson(map);
    var trackIds2 = sheetDetails.playlist.trackIds;
    List<int> ids = [];
    Future.forEach(trackIds2, (id)=>ids.add(id.id));
    var list = await getSongDetails(ids.join(','));
    sheetDetails.playlist.tracks = list;
    return sheetDetails;
  }

  //获取歌曲详情
  Future<List<SheetDetailsPlaylistTrack>> getSongDetails(ids) async{
    var songDetails;
    var map = await _doHandler('/song/detail',{'ids':ids});
    if(map!=null){
      var body = map['songs'];
      List<SheetDetailsPlaylistTrack> songs = [];
      await Future.forEach(body, (element){
        var sheetDetailsPlaylistTrack = SheetDetailsPlaylistTrack.fromJson(element);
        songs.add(sheetDetailsPlaylistTrack);
      });
      songDetails = songs;
    }
    return songDetails;
  }

  //每日推荐
  Future<TodaySongEntity> getTodaySongs() async{
    var todaySongs;
    var map = await _doHandler('/recommend/songs');
    if(map!=null) return TodaySongEntity.fromJson(map);
    return todaySongs;
  }
}