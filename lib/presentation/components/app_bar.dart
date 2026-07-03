import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlynote/common/constants.dart';
import 'package:onlynote/common/extension/map_index.dart';
import 'package:onlynote/presentation/components/components.dart';
import 'package:onlynote/presentation/routes/routes.dart';
import 'package:onlynote/presentation/theme/colors.dart';
import 'package:onlynote/presentation/theme/spacing.dart';
import 'package:onlynote/presentation/theme/typography.dart';

class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteAppBar({
    Key? key,
    this.autoImplementLeading = true,
    this.title,
    this.actions,
    this.systemUiOverlayStyle = SystemUiOverlayStyle.dark,
  }) : super(key: key);

  final bool autoImplementLeading;
  final String? title;
  final List<Widget>? actions;
  final SystemUiOverlayStyle systemUiOverlayStyle;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: systemUiOverlayStyle,
      child: FadeInDown(
        duration: animationDuration,
        child: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: AppColors.white),
            brightness: Brightness.light,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacings.xl),
            padding: const EdgeInsets.symmetric(vertical: AppSpacings.xl),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (autoImplementLeading)
                    AppButton(
                      child: const Icon(Icons.chevron_left),
                      onPressed: () {
                        context.router.maybePop("back");
                      },
                    ),
                  (title != null)
                      ? Expanded(
                          child: Text(
                            title!,
                            style: AppTypography.headline1.copyWith(color: AppColors.title),
                          ),
                        )
                      : const Spacer(),
                  if (actions != null) ...{
                    ...actions!
                        .mapIndexed(
                          (action, i) => Padding(
                            padding: (i == actions!.length - 1)
                                ? EdgeInsets.zero
                                : const EdgeInsets.only(right: AppSpacings.l),
                            child: action,
                          ),
                        )
                        .toList(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
