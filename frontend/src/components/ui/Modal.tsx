import React, { useEffect } from 'react';
import { clsx } from 'clsx';
import { XMarkIcon } from '@heroicons/react/24/outline';
import Button from './Button';

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  closeOnOverlay?: boolean;
  showCloseButton?: boolean;
}

interface ModalHeaderProps {
  children: React.ReactNode;
  onClose?: () => void;
  showCloseButton?: boolean;
}

interface ModalBodyProps {
  children: React.ReactNode;
  className?: string;
}

interface ModalFooterProps {
  children: React.ReactNode;
  className?: string;
}

const Modal: React.FC<ModalProps> & {
  Header: React.FC<ModalHeaderProps>;
  Body: React.FC<ModalBodyProps>;
  Footer: React.FC<ModalFooterProps>;
} = ({
  open,
  onClose,
  title,
  children,
  size = 'md',
  closeOnOverlay = true,
  showCloseButton = true,
}) => {
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && open) {
        onClose();
      }
    };

    if (open) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [open, onClose]);

  if (!open) return null;

  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
  };

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && closeOnOverlay) {
      onClose();
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-50 backdrop-blur-sm animate-fade-in"
      onClick={handleOverlayClick}
    >
      <div
        className={clsx(
          'relative w-full bg-white dark:bg-gray-800 rounded-xl shadow-soft-lg border border-gray-200 dark:border-gray-700 animate-fade-in-up',
          sizeClasses[size]
        )}
      >
        {(title || showCloseButton) && (
          <Modal.Header onClose={onClose} showCloseButton={showCloseButton}>
            {title}
          </Modal.Header>
        )}
        {children}
      </div>
    </div>
  );
};

const ModalHeader: React.FC<ModalHeaderProps> = ({ children, onClose, showCloseButton = true }) => (
  <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
    <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
      {children}
    </h3>
    {showCloseButton && onClose && (
      <Button
        variant="ghost"
        size="sm"
        onClick={onClose}
        className="p-1 h-8 w-8 rounded-full"
      >
        <XMarkIcon className="h-5 w-5" />
      </Button>
    )}
  </div>
);

const ModalBody: React.FC<ModalBodyProps> = ({ children, className }) => (
  <div className={clsx('px-6 py-4', className)}>
    {children}
  </div>
);

const ModalFooter: React.FC<ModalFooterProps> = ({ children, className }) => (
  <div className={clsx('flex items-center justify-end space-x-3 px-6 py-4 border-t border-gray-200 dark:border-gray-700', className)}>
    {children}
  </div>
);

Modal.Header = ModalHeader;
Modal.Body = ModalBody;
Modal.Footer = ModalFooter;

export default Modal;