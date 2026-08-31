import 'package:flutter/material.dart';


class AppTheme {
  // =========================================================
  // IDENTIDADE
  // =========================================================

  static const Color primary =
      Color(0xFF0D756D);

  static const Color primaryDark =
      Color(0xFF07544F);

  static const Color primaryDeep =
      Color(0xFF063E3B);

  static const Color primaryLight =
      Color(0xFF42A69C);

  static const Color background =
      Color(0xFFF2F7F5);

  static const Color surface =
      Color(0xFFFFFFFF);

  static const Color ink =
      Color(0xFF14211E);

  static const Color inkSoft =
      Color(0xFF64736F);

  static const Color line =
      Color(0xFFE3ECE9);

  static const Color danger =
      Color(0xFFD74E50);

  static const Color success =
      Color(0xFF2F8C70);

  static const Color accentBlue =
      Color(0xFF4F7CAC);


  // =========================================================
  // GRADIENTES
  // =========================================================

  static const LinearGradient
      backgroundGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7FBFA),
      Color(0xFFEAF4F1),
      Color(0xFFF4F8FA),
    ],
    stops: [
      0,
      0.55,
      1,
    ],
  );


  static const LinearGradient
      loginGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FCFB),
      Color(0xFFE9F4F0),
      Color(0xFFEAF1F5),
    ],
  );


  static const LinearGradient
      primaryGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D756D),
      Color(0xFF07544F),
    ],
  );


  static const LinearGradient
      premiumGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF143F4C),
      Color(0xFF0D756D),
      Color(0xFF2B6A78),
    ],
  );


  // =========================================================
  // SHADOWS
  // =========================================================

  static List<BoxShadow>
      get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: 0.045,
      ),
      blurRadius: 28,
      offset: const Offset(
        0,
        12,
      ),
    ),
  ];


  static List<BoxShadow>
      get floatingShadow => [
    BoxShadow(
      color: primaryDark.withValues(
        alpha: 0.12,
      ),
      blurRadius: 34,
      offset: const Offset(
        0,
        16,
      ),
    ),
  ];


  // =========================================================
  // GLASS
  // =========================================================

  static BoxDecoration
      glassDecoration({
    double radius = 24,
    double opacity = 0.70,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: opacity,
      ),
      borderRadius:
          BorderRadius.circular(
        radius,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.82,
        ),
        width: 1,
      ),
      boxShadow: softShadow,
    );
  }


  static BoxDecoration
      glassDarkDecoration({
    double radius = 26,
  }) {
    return BoxDecoration(
      gradient:
          premiumGradient,
      borderRadius:
          BorderRadius.circular(
        radius,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.16,
        ),
      ),
      boxShadow:
          floatingShadow,
    );
  }


  // =========================================================
  // TEMA
  // =========================================================

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
      seedColor:
          primary,
      brightness:
          Brightness.light,
    ).copyWith(
      primary:
          primary,
      secondary:
          primaryLight,
      surface:
          surface,
      error:
          danger,
      onSurface:
          ink,
    );


    return ThemeData(
      useMaterial3:
          true,

      colorScheme:
          colorScheme,

      scaffoldBackgroundColor:
          background,

      fontFamily:
          'Roboto',


      // =====================================================
      // TEXTO
      // =====================================================

      textTheme:
          const TextTheme(
        headlineLarge:
            TextStyle(
          fontSize:
              32,
          fontWeight:
              FontWeight.w800,
          letterSpacing:
              -1.0,
          color:
              ink,
        ),
        headlineMedium:
            TextStyle(
          fontSize:
              26,
          fontWeight:
              FontWeight.w800,
          letterSpacing:
              -0.7,
          color:
              ink,
        ),
        titleLarge:
            TextStyle(
          fontSize:
              20,
          fontWeight:
              FontWeight.w700,
          letterSpacing:
              -0.3,
          color:
              ink,
        ),
        titleMedium:
            TextStyle(
          fontSize:
              16,
          fontWeight:
              FontWeight.w700,
          color:
              ink,
        ),
        bodyLarge:
            TextStyle(
          fontSize:
              16,
          color:
              ink,
        ),
        bodyMedium:
            TextStyle(
          fontSize:
              14,
          color:
              inkSoft,
        ),
      ),


      // =====================================================
      // APP BAR
      // =====================================================

      appBarTheme:
          const AppBarTheme(
        backgroundColor:
            Colors.transparent,
        surfaceTintColor:
            Colors.transparent,
        foregroundColor:
            ink,
        elevation:
            0,
        scrolledUnderElevation:
            0,
        centerTitle:
            false,
        titleTextStyle:
            TextStyle(
          fontSize:
              21,
          fontWeight:
              FontWeight.w800,
          letterSpacing:
              -0.4,
          color:
              ink,
        ),
      ),


      // =====================================================
      // CARDS
      // =====================================================

      cardTheme:
          CardThemeData(
        color:
            Colors.white.withValues(
          alpha:
              0.82,
        ),
        surfaceTintColor:
            Colors.transparent,
        elevation:
            0,
        margin:
            const EdgeInsets.symmetric(
          vertical:
              6,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            22,
          ),
          side:
              BorderSide(
            color:
                Colors.white.withValues(
              alpha:
                  0.82,
            ),
          ),
        ),
      ),


      // =====================================================
      // INPUTS
      // =====================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled:
            true,
        fillColor:
            Colors.white.withValues(
          alpha:
              0.62,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal:
              18,
          vertical:
              18,
        ),
        labelStyle:
            const TextStyle(
          color:
              inkSoft,
          fontWeight:
              FontWeight.w500,
        ),
        hintStyle:
            TextStyle(
          color:
              inkSoft.withValues(
            alpha:
                0.65,
          ),
        ),
        prefixIconColor:
            inkSoft,
        suffixIconColor:
            inkSoft,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide(
            color:
                Colors.white.withValues(
              alpha:
                  0.78,
            ),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                primary,
            width:
                1.4,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                danger,
          ),
        ),
      ),


      // =====================================================
      // BOTÕES
      // =====================================================

      filledButtonTheme:
          FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
          backgroundColor:
              primary,
          foregroundColor:
              Colors.white,
          minimumSize:
              const Size.fromHeight(
            54,
          ),
          elevation:
              0,
          textStyle:
              const TextStyle(
            fontSize:
                15,
            fontWeight:
                FontWeight.w700,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              primary,
          foregroundColor:
              Colors.white,
          minimumSize:
              const Size.fromHeight(
            54,
          ),
          elevation:
              0,
          shadowColor:
              Colors.transparent,
          textStyle:
              const TextStyle(
            fontSize:
                15,
            fontWeight:
                FontWeight.w700,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),

      textButtonTheme:
          TextButtonThemeData(
        style:
            TextButton.styleFrom(
          foregroundColor:
              primary,
          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),


      // =====================================================
      // DIALOG
      // =====================================================

      dialogTheme:
          DialogThemeData(
        backgroundColor:
            Colors.white.withValues(
          alpha:
              0.96,
        ),
        surfaceTintColor:
            Colors.transparent,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            28,
          ),
        ),
      ),


      // =====================================================
      // BOTTOM SHEET
      // =====================================================

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor:
            Colors.transparent,
        surfaceTintColor:
            Colors.transparent,
      ),


      // =====================================================
      // SNACKBAR
      // =====================================================

      snackBarTheme:
          SnackBarThemeData(
        backgroundColor:
            ink,
        contentTextStyle:
            const TextStyle(
          color:
              Colors.white,
          fontWeight:
              FontWeight.w500,
        ),
        behavior:
            SnackBarBehavior.floating,
        elevation:
            0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),


      // =====================================================
      // DIVISORES
      // =====================================================

      dividerTheme:
          const DividerThemeData(
        color:
            line,
        thickness:
            1,
        space:
            1,
      ),


      // =====================================================
      // ICONS
      // =====================================================

      iconTheme:
          const IconThemeData(
        color:
            ink,
      ),


      // =====================================================
      // RIPPLE
      // =====================================================

      splashFactory:
          InkSparkle
              .splashFactory,
    );
  }
}