import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'app_icon.dart';

export 'app_icon.dart';

/// Central token registry for all icons used throughout the POS application.
/// Provides consistent mapping between semantic names, Phosphor icons (regular & duotone),
/// and custom domain SVGs.
class AppIcons {
  AppIcons._();

  // --- Domain SVGs ---
  static const AppIconData liquorBottle =
      AppIconData.svg('assets/icons/domain/liquor_bottle.svg');
  static const AppIconData crate =
      AppIconData.svg('assets/icons/domain/crate.svg');
  static const AppIconData exciseSeal =
      AppIconData.svg('assets/icons/domain/excise_seal.svg');

  // --- Navigation & Core Shell ---
  static const AppIconData dashboard = AppIconData.phosphor(
      PhosphorIconsRegular.squaresFour, PhosphorIconsDuotone.squaresFour);
  static const AppIconData pos = AppIconData.phosphor(
      PhosphorIconsRegular.cashRegister, PhosphorIconsDuotone.cashRegister);
  static const AppIconData salesReturn = AppIconData.phosphor(
      PhosphorIconsRegular.arrowCounterClockwise,
      PhosphorIconsDuotone.arrowCounterClockwise);
  static const AppIconData purchaseBill = AppIconData.phosphor(
      PhosphorIconsRegular.receipt, PhosphorIconsDuotone.receipt);
  static const AppIconData purchaseReturn = AppIconData.phosphor(
      PhosphorIconsRegular.arrowUUpLeft, PhosphorIconsDuotone.arrowUUpLeft);
  static const AppIconData inventory = AppIconData.phosphor(
      PhosphorIconsRegular.package, PhosphorIconsDuotone.package);
  static const AppIconData categories = AppIconData.phosphor(
      PhosphorIconsRegular.folderSimple, PhosphorIconsDuotone.folderSimple);
  static const AppIconData suppliers = AppIconData.phosphor(
      PhosphorIconsRegular.truck, PhosphorIconsDuotone.truck);
  static const AppIconData manufacturers = AppIconData.phosphor(
      PhosphorIconsRegular.buildings, PhosphorIconsDuotone.buildings);
  static const AppIconData packagings = AppIconData.phosphor(
      PhosphorIconsRegular.archive, PhosphorIconsDuotone.archive);
  static const AppIconData licenseHolders = AppIconData.phosphor(
      PhosphorIconsRegular.identificationCard,
      PhosphorIconsDuotone.identificationCard);
  static const AppIconData allMasters = AppIconData.phosphor(
      PhosphorIconsRegular.squaresFour, PhosphorIconsDuotone.squaresFour);
  static const AppIconData materials = AppIconData.phosphor(
      PhosphorIconsRegular.stack, PhosphorIconsDuotone.stack);
  static const AppIconData reports = AppIconData.phosphor(
      PhosphorIconsRegular.chartBar, PhosphorIconsDuotone.chartBar);
  static const AppIconData brandwise = AppIconData.phosphor(
      PhosphorIconsRegular.wine, PhosphorIconsDuotone.wine);
  static const AppIconData sync = AppIconData.phosphor(
      PhosphorIconsRegular.arrowsClockwise,
      PhosphorIconsDuotone.arrowsClockwise);
  static const AppIconData logout = AppIconData.phosphor(
      PhosphorIconsRegular.signOut, PhosphorIconsDuotone.signOut);
  static const AppIconData brandLogo = AppIconData.phosphor(
      PhosphorIconsRegular.wine, PhosphorIconsDuotone.wine);

  // --- Actions & Buttons ---
  static const AppIconData search = AppIconData.phosphor(
      PhosphorIconsRegular.magnifyingGlass,
      PhosphorIconsDuotone.magnifyingGlass);
  static const AppIconData searchOff = AppIconData.phosphor(
      PhosphorIconsRegular.magnifyingGlass,
      PhosphorIconsDuotone.magnifyingGlass);
  static const AppIconData filter = AppIconData.phosphor(
      PhosphorIconsRegular.funnel, PhosphorIconsDuotone.funnel);
  static const AppIconData filterClear = AppIconData.phosphor(
      PhosphorIconsRegular.funnelSimple, PhosphorIconsDuotone.funnelSimple);
  static const AppIconData download = AppIconData.phosphor(
      PhosphorIconsRegular.downloadSimple, PhosphorIconsDuotone.downloadSimple);
  static const AppIconData upload = AppIconData.phosphor(
      PhosphorIconsRegular.uploadSimple, PhosphorIconsDuotone.uploadSimple);
  static const AppIconData refresh = AppIconData.phosphor(
      PhosphorIconsRegular.arrowsClockwise,
      PhosphorIconsDuotone.arrowsClockwise);
  static const AppIconData add = AppIconData.phosphor(
      PhosphorIconsRegular.plus, PhosphorIconsDuotone.plusCircle);
  static const AppIconData addCircle = AppIconData.phosphor(
      PhosphorIconsRegular.plusCircle, PhosphorIconsDuotone.plusCircle);
  static const AppIconData remove = AppIconData.phosphor(
      PhosphorIconsRegular.minus, PhosphorIconsDuotone.minusCircle);
  static const AppIconData delete = AppIconData.phosphor(
      PhosphorIconsRegular.trash, PhosphorIconsDuotone.trash);
  static const AppIconData clearAll = AppIconData.phosphor(
      PhosphorIconsRegular.broom, PhosphorIconsDuotone.broom);
  static const AppIconData close = AppIconData.phosphor(
      PhosphorIconsRegular.x, PhosphorIconsDuotone.xCircle);
  static const AppIconData edit = AppIconData.phosphor(
      PhosphorIconsRegular.pencilSimple, PhosphorIconsDuotone.pencilSimple);
  static const AppIconData editNote = AppIconData.phosphor(
      PhosphorIconsRegular.notePencil, PhosphorIconsDuotone.notePencil);
  static const AppIconData save = AppIconData.phosphor(
      PhosphorIconsRegular.floppyDisk, PhosphorIconsDuotone.floppyDisk);
  static const AppIconData check = AppIconData.phosphor(
      PhosphorIconsRegular.check, PhosphorIconsDuotone.checkCircle);
  static const AppIconData checkCircle = AppIconData.phosphor(
      PhosphorIconsRegular.checkCircle, PhosphorIconsDuotone.checkCircle);
  static const AppIconData lock = AppIconData.phosphor(
      PhosphorIconsRegular.lockKey, PhosphorIconsDuotone.lockKey);
  static const AppIconData lockOpen = AppIconData.phosphor(
      PhosphorIconsRegular.lockKeyOpen, PhosphorIconsDuotone.lockKeyOpen);
  static const AppIconData paste = AppIconData.phosphor(
      PhosphorIconsRegular.clipboardText, PhosphorIconsDuotone.clipboardText);
  static const AppIconData calculator = AppIconData.phosphor(
      PhosphorIconsRegular.calculator, PhosphorIconsDuotone.calculator);
  static const AppIconData keyboard = AppIconData.phosphor(
      PhosphorIconsRegular.keyboard, PhosphorIconsDuotone.keyboard);
  static const AppIconData darkMode = AppIconData.phosphor(
      PhosphorIconsRegular.moon, PhosphorIconsDuotone.moon);
  static const AppIconData lightMode = AppIconData.phosphor(
      PhosphorIconsRegular.sun, PhosphorIconsDuotone.sun);
  static const AppIconData fontSize = AppIconData.phosphor(
      PhosphorIconsRegular.textAa, PhosphorIconsDuotone.textAa);
  static const AppIconData tune = AppIconData.phosphor(
      PhosphorIconsRegular.slidersHorizontal,
      PhosphorIconsDuotone.slidersHorizontal);
  static const AppIconData print = AppIconData.phosphor(
      PhosphorIconsRegular.printer, PhosphorIconsDuotone.printer);
  static const AppIconData openInNew = AppIconData.phosphor(
      PhosphorIconsRegular.arrowSquareOut, PhosphorIconsDuotone.arrowSquareOut);
  static const AppIconData swapHoriz = AppIconData.phosphor(
      PhosphorIconsRegular.arrowsLeftRight,
      PhosphorIconsDuotone.arrowsLeftRight);
  static const AppIconData settings = AppIconData.phosphor(
      PhosphorIconsRegular.gear, PhosphorIconsDuotone.gear);

  // --- Arrows & Chevrons ---
  static const AppIconData chevronLeft = AppIconData.phosphor(
      PhosphorIconsRegular.caretLeft, PhosphorIconsDuotone.caretLeft);
  static const AppIconData chevronRight = AppIconData.phosphor(
      PhosphorIconsRegular.caretRight, PhosphorIconsDuotone.caretRight);
  static const AppIconData arrowDown = AppIconData.phosphor(
      PhosphorIconsRegular.arrowDown, PhosphorIconsDuotone.arrowDown);
  static const AppIconData arrowUp = AppIconData.phosphor(
      PhosphorIconsRegular.arrowUp, PhosphorIconsDuotone.arrowUp);
  static const AppIconData arrowForward = AppIconData.phosphor(
      PhosphorIconsRegular.arrowRight, PhosphorIconsDuotone.arrowRight);
  static const AppIconData arrowDropDown = AppIconData.phosphor(
      PhosphorIconsRegular.caretDown, PhosphorIconsDuotone.caretDown);
  static const AppIconData keyboardArrowDown = AppIconData.phosphor(
      PhosphorIconsRegular.caretDown, PhosphorIconsDuotone.caretDown);
  static const AppIconData unfoldMore = AppIconData.phosphor(
      PhosphorIconsRegular.caretUpDown, PhosphorIconsDuotone.caretUpDown);
  static const AppIconData trendingUp = AppIconData.phosphor(
      PhosphorIconsRegular.trendUp, PhosphorIconsDuotone.trendUp);
  static const AppIconData northEast = AppIconData.phosphor(
      PhosphorIconsRegular.arrowUpRight, PhosphorIconsDuotone.arrowUpRight);
  static const AppIconData southEast = AppIconData.phosphor(
      PhosphorIconsRegular.arrowDownRight, PhosphorIconsDuotone.arrowDownRight);

  // --- POS / Retail / Domain ---
  static const AppIconData cash = AppIconData.phosphor(
      PhosphorIconsRegular.money, PhosphorIconsDuotone.money);
  static const AppIconData creditCard = AppIconData.phosphor(
      PhosphorIconsRegular.creditCard, PhosphorIconsDuotone.creditCard);
  static const AppIconData qrCode = AppIconData.phosphor(
      PhosphorIconsRegular.qrCode, PhosphorIconsDuotone.qrCode);
  static const AppIconData barcode = AppIconData.phosphor(
      PhosphorIconsRegular.barcode, PhosphorIconsDuotone.barcode);
  static const AppIconData rupee = AppIconData.phosphor(
      PhosphorIconsRegular.currencyInr, PhosphorIconsDuotone.currencyInr);
  static const AppIconData receipt = AppIconData.phosphor(
      PhosphorIconsRegular.receipt, PhosphorIconsDuotone.receipt);
  static const AppIconData shoppingBag = AppIconData.phosphor(
      PhosphorIconsRegular.shoppingBag, PhosphorIconsDuotone.shoppingBag);
  static const AppIconData cart = AppIconData.phosphor(
      PhosphorIconsRegular.shoppingCart, PhosphorIconsDuotone.shoppingCart);
  static const AppIconData cartRemove = AppIconData.phosphor(
      PhosphorIconsRegular.shoppingCartSimple,
      PhosphorIconsDuotone.shoppingCartSimple);
  static const AppIconData calendar = AppIconData.phosphor(
      PhosphorIconsRegular.calendarBlank, PhosphorIconsDuotone.calendarBlank);
  static const AppIconData calendarMonth = AppIconData.phosphor(
      PhosphorIconsRegular.calendar, PhosphorIconsDuotone.calendar);
  static const AppIconData time = AppIconData.phosphor(
      PhosphorIconsRegular.clock, PhosphorIconsDuotone.clock);
  static const AppIconData store = AppIconData.phosphor(
      PhosphorIconsRegular.storefront, PhosphorIconsDuotone.storefront);
  static const AppIconData storefront = AppIconData.phosphor(
      PhosphorIconsRegular.storefront, PhosphorIconsDuotone.storefront);
  static const AppIconData beer = AppIconData.phosphor(
      PhosphorIconsRegular.beerBottle, PhosphorIconsDuotone.beerBottle);
  static const AppIconData wineBar = AppIconData.phosphor(
      PhosphorIconsRegular.wine, PhosphorIconsDuotone.wine);
  static const AppIconData wine = AppIconData.phosphor(
      PhosphorIconsRegular.wine, PhosphorIconsDuotone.wine);
  static const AppIconData bank = AppIconData.phosphor(
      PhosphorIconsRegular.bank, PhosphorIconsDuotone.bank);
  static const AppIconData wallet = AppIconData.phosphor(
      PhosphorIconsRegular.wallet, PhosphorIconsDuotone.wallet);
  static const AppIconData people = AppIconData.phosphor(
      PhosphorIconsRegular.users, PhosphorIconsDuotone.users);
  static const AppIconData factory = AppIconData.phosphor(
      PhosphorIconsRegular.factory, PhosphorIconsDuotone.factory);
  static const AppIconData tag = AppIconData.phosphor(
      PhosphorIconsRegular.tag, PhosphorIconsDuotone.tag);
  static const AppIconData badge = AppIconData.phosphor(
      PhosphorIconsRegular.sealCheck, PhosphorIconsDuotone.sealCheck);
  static const AppIconData warning = AppIconData.phosphor(
      PhosphorIconsRegular.warning, PhosphorIconsDuotone.warning);
  static const AppIconData info = AppIconData.phosphor(
      PhosphorIconsRegular.info, PhosphorIconsDuotone.info);
  static const AppIconData error = AppIconData.phosphor(
      PhosphorIconsRegular.warningCircle, PhosphorIconsDuotone.warningCircle);
  static const AppIconData block = AppIconData.phosphor(
      PhosphorIconsRegular.prohibit, PhosphorIconsDuotone.prohibit);
  static const AppIconData uploadFile = AppIconData.phosphor(
      PhosphorIconsRegular.fileArrowUp, PhosphorIconsDuotone.fileArrowUp);
  static const AppIconData business = AppIconData.phosphor(
      PhosphorIconsRegular.buildings, PhosphorIconsDuotone.buildings);
  static const AppIconData addBusiness = AppIconData.phosphor(
      PhosphorIconsRegular.storefront, PhosphorIconsDuotone.storefront);
  static const AppIconData allInbox = AppIconData.phosphor(
      PhosphorIconsRegular.archive, PhosphorIconsDuotone.archive);
  static const AppIconData category = AppIconData.phosphor(
      PhosphorIconsRegular.tag, PhosphorIconsDuotone.tag);
}
