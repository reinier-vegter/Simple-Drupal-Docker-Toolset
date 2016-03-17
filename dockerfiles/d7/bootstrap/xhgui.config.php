<?php
/**
 * Default configuration for Xhgui
 */

$url = $_SERVER['REQUEST_URI'];
return array(
  'debug' => false,
  'mode' => 'development',

  'save.handler' => 'file',
  'save.handler.filename' => dirname(__DIR__) . '/cache/' . 'xhgui.data.' . microtime(true) . '_' . substr(md5($url), 0, 6),

  'templates.path' => dirname(__DIR__) . '/src/templates',
  'date.format' => 'M jS H:i:s',
  'detail.count' => 6,
  'page.limit' => 25,

  // Profile 1 in 100 requests.
  // You can return true to profile every request.
  'profiler.enable' => function() {
    return TRUE;
//    return rand(0, 100) === 42;
  },

  'profiler.simple_url' => function($url) {
    return preg_replace('/\=\d+/', '', $url);
  }
);
