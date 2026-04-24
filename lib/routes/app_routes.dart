part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();

  static const SPLASH = _Paths.SPLASH;
  static const INTRO = _Paths.INTRO;
  static const LOGIN_OPTIONS = _Paths.LOGIN_OPTIONS;
  static const CLIENT_LOGIN = _Paths.CLIENT_LOGIN;
  static const ADMIN_LOGIN = _Paths.ADMIN_LOGIN;
  static const EMPLOYEE_LOGIN = _Paths.EMPLOYEE_LOGIN;
  static const ADMIN_REG = _Paths.ADMIN_REG;
  static const EMPLOYEE_REG = _Paths.EMPLOYEE_REG;
  static const FIND_YOUR_ORG = _Paths.FIND_YOUR_ORG;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  static const ADMIN_DASHBOARD = _Paths.ADMIN_DASHBOARD;
  static const ADMIN_EMPLOYEE = _Paths.ADMIN_EMPLOYEE;
  static const ADMIN_DEPARTMENT = _Paths.ADMIN_DEPARTMENT;
  static const ADMIN_ADD_DEPARTMENT =
      _Paths.ADMIN_DEPARTMENT + _Paths.ADMIN_ADD_DEPARTMENT;
  static const ADMIN_ADD_EMPLOYEE =
      _Paths.ADMIN_EMPLOYEE + _Paths.ADMIN_ADD_EMPLOYEE;
  static const ADMIN_NOTIFICATION = _Paths.ADMIN_NOTIFICATION;
  static const ADMIN_ROLES = _Paths.ADMIN_ROLES;
  static const ADMIN_ADD_ROLE = _Paths.ADMIN_ROLES + _Paths.ADMIN_ADD_ROLE;
  static const ADMIN_PERMISSION = _Paths.ADMIN_PERMISSION;
  static const ADMIN_ADD_PERMISSION = _Paths.ADMIN_ADD_PERMISSION;
  static const ADMIN_GOALS = _Paths.ADMIN_GOALS;
  static const ADMIN_ADD_GOAL = _Paths.ADMIN_GOALS + _Paths.ADMIN_ADD_GOAL;
  static const ADMIN_DETAILS_GOAL =
      _Paths.ADMIN_GOALS + _Paths.ADMIN_DETAILS_GOAL;
  static const ADMIN_ADD_KEY_RESULT =
      _Paths.ADMIN_GOALS + _Paths.ADMIN_ADD_KEY_RESULT;
  static const ADMIN_LIVE_BOARD = _Paths.ADMIN_LIVE_BOARD;
  static const ADMIN_LIVE_BOARD_DETAILS = _Paths.ADMIN_LIVE_BOARD_DETAILS;
  static const ADMIN_TO_DO = _Paths.ADMIN_TO_DO;
  static const ADMIN_ADD_TO_DO = _Paths.ADMIN_TO_DO + _Paths.ADMIN_ADD_TO_DO;
  static const ADMIN_CREATE_NEW_CATEGORY =
      _Paths.ADMIN_TO_DO + _Paths.ADMIN_CREATE_NEW_CATEGORY;
  static const ADMIN_TO_DO_DETAILS =
      _Paths.ADMIN_TO_DO + _Paths.ADMIN_TO_DO_DETAILS;
  static const ADMIN_MEETINGS = _Paths.ADMIN_MEETINGS;
  static const ADMIN_LEAVE_MANAGEMENT = _Paths.ADMIN_LEAVE_MANAGEMENT;
  static const ADMIN_TEAMS = _Paths.ADMIN_TEAMS;
  static const ADMIN_PROJECTS = _Paths.ADMIN_PROJECTS;
  static const ADMIN_PROJECT_DETAILS = _Paths.ADMIN_PROJECT_DETAILS;
  static const ADMIN_CREATE_PROJECT = _Paths.ADMIN_CREATE_PROJECT;
  static const ADMIN_SETTINGS = _Paths.ADMIN_SETTINGS;
  static const BOARDS_TODO_DETAILS = _Paths.BOARDS_TODO_DETAILS;
  static const ADMIN_CREATE_TASK = _Paths.ADMIN_CREATE_TASK;
  
  // Common routes (for both admin and employee)
  static const CHAT_LISTING = _Paths.CHAT_LISTING;
  static const CHAT_MESSAGES = _Paths.CHAT_MESSAGES;
  static const SETTINGS = _Paths.SETTINGS;
  
  // Employee routes
  static const EMPLOYEE_LIVE_BOARD = _Paths.EMPLOYEE_LIVE_BOARD;
  static const EMPLOYEE_LIVE_BOARD_DETAILS = _Paths.EMPLOYEE_LIVE_BOARD_DETAILS;
  static const EMPLOYEE_DASHBOARD = _Paths.EMPLOYEE_DASHBOARD;
  static const EMPLOYEE_GOALS = _Paths.EMPLOYEE_GOALS;
  static const EMPLOYEE_GOAL_DETAILS = _Paths.EMPLOYEE_GOAL_DETAILS;
  static const EMPLOYEE_PROJECT_DETAILS = _Paths.EMPLOYEE_PROJECT_DETAILS;
  static const EMPLOYEE_TO_DO = _Paths.EMPLOYEE_TO_DO;
  static const EMPLOYEE_ADD_TO_DO = _Paths.EMPLOYEE_TO_DO + _Paths.EMPLOYEE_ADD_TO_DO;
  static const EMPLOYEE_CREATE_NEW_CATEGORY =
      _Paths.EMPLOYEE_TO_DO + _Paths.EMPLOYEE_CREATE_NEW_CATEGORY;
  static const EMPLOYEE_TO_DO_DETAILS =
      _Paths.EMPLOYEE_TO_DO + _Paths.EMPLOYEE_TO_DO_DETAILS;
  static const EMPLOYEE_BOARDS_TODO_DETAILS = _Paths.EMPLOYEE_BOARDS_TODO_DETAILS;
  static const EMPLOYEE_CREATE_TASK = _Paths.EMPLOYEE_CREATE_TASK;
  static const EMPLOYEE_LEAVES = _Paths.EMPLOYEE_LEAVES;
  static const EMPLOYEE_MEETINGS = _Paths.EMPLOYEE_MEETINGS;

  // Test routes
  static const BOTTOM_NAV_TEST = _Paths.BOTTOM_NAV_TEST;
}

abstract class _Paths {
  _Paths._();

  static const SPLASH = '/splash';
  static const INTRO = '/intro';
  static const LOGIN_OPTIONS = '/login-options';
  static const CLIENT_LOGIN = '/client-login';
  static const ADMIN_LOGIN = '/admin-login';
  static const EMPLOYEE_LOGIN = '/employee-login';
  static const ADMIN_REG = '/admin-reg';
  static const EMPLOYEE_REG = '/employee-reg';
  static const FIND_YOUR_ORG = '/find-your-org';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const ADMIN_DASHBOARD = '/admin-dashboard';
  static const ADMIN_EMPLOYEE = '/admin-employee';
  static const ADMIN_DEPARTMENT = '/admin-department';
  static const ADMIN_ADD_DEPARTMENT = '/admin-add-department';
  static const ADMIN_ADD_EMPLOYEE = '/admin-add-employee';
  static const ADMIN_NOTIFICATION = '/admin-notification';
  static const ADMIN_ROLES = '/admin-roles';
  static const ADMIN_ADD_ROLE = '/admin-add-role';
  static const ADMIN_PERMISSION = '/admin-permission';
  static const ADMIN_ADD_PERMISSION = '/admin-add-permission';
  static const ADMIN_GOALS = '/admin-goals';
  static const ADMIN_ADD_GOAL = '/admin-add-goal';
  static const ADMIN_DETAILS_GOAL = '/admin-details-goal';
  static const ADMIN_ADD_KEY_RESULT = '/admin-add-key-result';
  static const ADMIN_LIVE_BOARD = '/admin-live-board';
  static const ADMIN_LIVE_BOARD_DETAILS = '/admin-live-board-details';
  static const ADMIN_TO_DO = '/admin-to-do';
  static const ADMIN_ADD_TO_DO = '/admin-add-to-do';
  static const ADMIN_CREATE_NEW_CATEGORY = '/admin-create-new-category';
  static const ADMIN_TO_DO_DETAILS = '/admin-to-do-details';
  static const ADMIN_MEETINGS = '/admin-meetings';
  static const ADMIN_LEAVE_MANAGEMENT = '/admin-leave-management';
  static const ADMIN_TEAMS = '/admin-teams';
  static const ADMIN_PROJECTS = '/admin-projects';
  static const ADMIN_PROJECT_DETAILS = '/admin-project-details';
  static const ADMIN_CREATE_PROJECT = '/admin-create-project';
  static const ADMIN_SETTINGS = '/admin-settings';
  static const BOARDS_TODO_DETAILS = '/boards-todo-details';
  static const ADMIN_CREATE_TASK = '/admin-create-task';
  
  // Common routes (for both admin and employee)
  static const CHAT_LISTING = '/chat-listing';
  static const CHAT_MESSAGES = '/chat-messages';
  static const SETTINGS = '/employee_settings';
  
  // Employee routes
  static const EMPLOYEE_LIVE_BOARD = '/employee-live-board';
  static const EMPLOYEE_LIVE_BOARD_DETAILS = '/employee-live-board-details';
  static const EMPLOYEE_DASHBOARD = '/employee-dashboard';
  static const EMPLOYEE_GOALS = '/employee-goals';
  static const EMPLOYEE_GOAL_DETAILS = '/employee-goal-details';
  static const EMPLOYEE_PROJECT_DETAILS = '/employee-project-details';
  static const EMPLOYEE_TO_DO = '/employee-to-do';
  static const EMPLOYEE_ADD_TO_DO = '/employee-add-to-do';
  static const EMPLOYEE_CREATE_NEW_CATEGORY = '/employee-create-new-category';
  static const EMPLOYEE_TO_DO_DETAILS = '/employee-to-do-details';
  static const EMPLOYEE_BOARDS_TODO_DETAILS = '/employee-boards-todo-details';
  static const EMPLOYEE_CREATE_TASK = '/employee-create-task';
  static const EMPLOYEE_LEAVES = '/employee-leaves';
  static const EMPLOYEE_MEETINGS = '/employee-meetings';

  // Test routes
  static const BOTTOM_NAV_TEST = '/bottom-nav-test';
}
