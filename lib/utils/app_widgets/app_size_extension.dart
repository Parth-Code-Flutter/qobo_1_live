import 'package:aligned_rewards/utils/ui_utils/app_screen_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension AppSizeExtension on num {
  double get screenHeight => AppScreenUtils.height * this;

  double get screenWidth => AppScreenUtils.width * this;

  double get appHeight => ScreenUtil().setHeight(this);

  double get appWidth => ScreenUtil().setWidth(this);

  double get appText => ScreenUtil().setSp(this);
}
