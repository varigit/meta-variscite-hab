require ${@ 'linux-var-signature.inc' if 'hab' in d.getVar('OVERRIDES').split(':') else ('linux-var-ahab-signature.inc' if 'ahab' in d.getVar('OVERRIDES').split(':') else '')}
