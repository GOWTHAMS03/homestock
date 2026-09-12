package com.homestock.core.security;

import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        User user = userRepository.findByIdentifier(identifier.trim())
                .orElseThrow(() -> new UsernameNotFoundException("User not found with identifier: " + identifier));
        if (user.isDeleted()) {
            throw new UsernameNotFoundException("User account has been deleted");
        }
        return UserPrincipal.create(user);
    }

    @Transactional(readOnly = true)
    public UserDetails loadUserById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new com.homestock.core.exception.UserNotFoundException("User not found with id: " + id));
        if (user.isDeleted()) {
            throw new com.homestock.core.exception.UserNotFoundException("This HomeStock account could not be verified. Please sign in again.");
        }
        if (!user.isAccountActive()) {
            throw new com.homestock.core.exception.AccountDisabledException("This HomeStock account is disabled.");
        }
        return UserPrincipal.create(user);
    }
}
