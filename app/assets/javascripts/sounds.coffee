$ ->
  ion.sound({
    sounds: [
      {alias: 'incoming_call', name: "ringtone"},
      {alias: 'outgoing_call', name: "calling"},
      {alias: 'end_call', name: "end_of_call"},
      {alias: 'general_notification', name: "chime_bell_ding"},
      {alias: 'new_message', name: "pop_banner_bible_sound"},
      {alias: 'audio_sent', name: "message_sent"},
    ],
    path: "/audio/",
    preload: false,
    multiplay: true,
    volume: 0.9
  });